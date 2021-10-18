import math
import numpy as np
import random
import shapely
import shapely.prepared
import tempfile

from .utils.calc import obstacles_and_boundary_from_occupancy_grid
from .world import World
from unitybridge import UnityBridge


class WorldBuildingUnityBridge(UnityBridge):
    """Connection between World object and unity"""
    def make_world(self, world, scale=10.0):
        self.do_buffer = True

        def dist(p1, p2):
            return math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

        self.send_message("main_builder floor")

        for obstacle in world.obstacles:
            points = obstacle.exterior.coords
            print(points)
            spoints = points[1:] + points[-1:]
            for pa, pb in zip(points, spoints):
                coords = ""
                nsegs = int(dist(pa, pb) / scale + 0.5)
                nsegs = max(nsegs, 1)
                xs = np.linspace(pa[0], pb[0], nsegs + 1, endpoint=True)
                ys = np.linspace(pa[1], pb[1], nsegs + 1, endpoint=True)

                for x, y in zip(xs, ys):
                    coords += " {} {}".format(y, x)

                message = "main_builder dungeon_poly" + coords
                print(message)
                self.send_message(message)

        for pose in world.clutter_element_poses:
            self.create_object(command_name='clutter',
                               pose=pose,
                               height=random.random() * 0.5 - 4.0 + 1.0)

        for pose in world.breadcrumb_element_poses:
            self.create_object(command_name='breadcrumb',
                               pose=pose,
                               height=0.05 - 4.0)

        self.do_buffer = False
        with tempfile.NamedTemporaryFile("w", delete=False) as temp_file:
            for message in self.messages:
                temp_file.write(message + "\n")

        self.send_message(f"main_builder file {temp_file.name}", 0.0)
        self.unity_listener.parse_string()

    def move_object_to_pose(self, object_name, pose, pause=-1):
        if pause <= 0:
            self.send_message("{} move_respond {} {} {} {}".format(
                object_name, pose.y, 1.5, pose.x, pose.yaw),
                              pause=pause)
            self.unity_listener.parse_string()
        else:
            self.send_message("{} move {} {} {} {}".format(
                object_name, pose.y, 1.5, pose.x, pose.yaw),
                              pause=pause)


class OccupancyGridWorld(World):
    """Use occupancy grid to improve planning efficiency"""
    def __init__(self,
                 grid,
                 map_data,
                 num_breadcrumb_elements=500,
                 min_breadcrumb_signed_distance=4.0):
        self.grid = (1.0 - grid.T)  # Differences in occupancy value
        self.map_data = map_data
        self.resolution = map_data['resolution']
        print(f"OGW resolution: {map_data['resolution']}")

        obstacles, boundary = obstacles_and_boundary_from_occupancy_grid(
            self.grid, self.resolution)

        self.x = (np.arange(0, self.grid.shape[0]) + 0.0) * self.resolution
        self.y = (np.arange(0, self.grid.shape[1]) + 0.0) * self.resolution

        super(OccupancyGridWorld, self).__init__(obstacles=obstacles,
                                                 boundary=boundary)

        # Add clutter (intersects walls)
        self.breadcrumb_element_poses = []
        while len(self.breadcrumb_element_poses) < num_breadcrumb_elements:
            pose = self.get_random_pose(
                min_signed_dist=min_breadcrumb_signed_distance,
                semantic_label='goal_path')
            signed_dist = self.get_signed_dist(pose)
            if signed_dist >= min_breadcrumb_signed_distance:
                self.breadcrumb_element_poses.append(pose)

    def get_random_pose(self,
                        xbounds=None,
                        ybounds=None,
                        min_signed_dist=0,
                        num_attempts=10000,
                        semantic_label=None):
        """Get a random pose in the world, respecting the signed distance
        to all the obstacles.

        Each "bound" is a N-element list structured such that:

        > xmin = min(xbounds)
        > xmax = max(xbounds)

        "num_attempts" is the number of trials before an error is raised.

        """

        for _ in range(num_attempts):
            pose = super(OccupancyGridWorld,
                         self).get_random_pose(xbounds, ybounds,
                                               min_signed_dist, num_attempts)
            if semantic_label is None:
                return pose

            pose_cell_x = np.argmin(np.abs(self.y - pose.x))
            pose_cell_y = np.argmin(np.abs(self.x - pose.y))

            grid_label_ind = self.map_data['semantic_grid'][pose_cell_x,
                                                            pose_cell_y]
            if grid_label_ind == self.map_data['semantic_labels'][
                    semantic_label]:
                return pose
        else:
            raise ValueError("Could not find random point within bounds")

    def get_grid_from_poly(self, known_space_poly, proposed_world=None):
        known_space_poly = known_space_poly.buffer(self.resolution / 2)
        mask = -1 * np.ones(self.grid.shape)

        for ii in range(mask.shape[0]):
            for jj in range(mask.shape[1]):
                p = shapely.geometry.Point(self.y[jj], self.x[ii])
                if known_space_poly.contains(p):
                    mask[ii, jj] = 1

        out_grid = -1.0 * np.ones(mask.shape)
        out_grid[mask == 1] = 0.0

        if proposed_world is not None:
            for v in proposed_world.vertices:
                cell_y = np.argmin(np.abs(self.y - v[0]))
                cell_x = np.argmin(np.abs(self.x - v[1]))
                out_grid[cell_x, cell_y] = 1.0

            for w in proposed_world.walls:
                ys = np.linspace(w[0][0], w[1][0], 100)
                xs = np.linspace(w[0][1], w[1][1], 100)

                for x, y in zip(xs, ys):
                    cell_x = np.argmin(np.abs(self.x - x))
                    cell_y = np.argmin(np.abs(self.y - y))
                    out_grid[cell_x, cell_y] = 1.0

        return out_grid.T
