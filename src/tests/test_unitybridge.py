import common
import environments
import numpy as np
import time
from shapely import geometry

from .fixtures import unity_path  # noqa


def get_map_and_path_hall_snake():
    maze_poly = geometry.Polygon([(10, -10), (10, 20), (50, 20), (50, 50),
                                  (70, 50), (70, 00), (130, 00), (130, 20),
                                  (90, 20), (90, 70), (30, 70), (30, 40),
                                  (-10, 40), (-10, -10)])
    path = [(40, 30), (40, 60), (80, 60), (80, 10), (120, 10)]
    return environments.world.World(obstacles=[maze_poly]), path


def follow_path_data_iterator(unity_bridge, world, path, steps=50, pause=None):
    """Loop through data along a path."""
    stime = time.time()
    unity_bridge.make_world(world)
    print(f"Time to Make World: {time.time() - stime}")
    pose_generator = (common.Pose(
        ii * 1.0 * seg[1][0] / steps + (1 - ii * 1.0 / steps) * seg[0][0],
        ii * 1.0 * seg[1][1] / steps + (1 - ii * 1.0 / steps) * seg[0][1])
                      for seg in zip(path[:-1], path[1:])
                      for ii in range(steps))

    for pose in pose_generator:
        # Get the images
        if pause is not None:
            unity_bridge.move_object_to_pose("quad", pose, pause)
            pano_image = unity_bridge.get_image("quad/t_pano_camera", pause)
            pano_depth_image = unity_bridge.get_image(
                "quad/t_pano_depth_camera", pause)
        else:
            pano_image = unity_bridge.get_image("quad/t_pano_camera")
            pano_depth_image = unity_bridge.get_image(
                "quad/t_pano_depth_camera")
            unity_bridge.move_object_to_pose("quad", pose)

        pano_image = pano_image[64:-64] * 1.0 / 255
        ranges = environments.utils.convert.ranges_from_depth_image(
            pano_depth_image)

        yield pose, pano_image, ranges


def test_unitybridge_snake(unity_path):  # noqa
    world, path = get_map_and_path_hall_snake()
    world.breadcrumb_element_poses = []

    world_building_unity_bridge = \
        environments.simulated.WorldBuildingUnityBridge

    slow_images = []
    stime = time.time()
    with world_building_unity_bridge(unity_path) as unity_bridge:
        data_iterator = follow_path_data_iterator(unity_bridge,
                                                  world,
                                                  path,
                                                  steps=10,
                                                  pause=0.1)
        for pose, image, ranges in data_iterator:
            slow_images.append(image)
            assert min(ranges) < 11.0
            assert min(ranges) > 9.0

    print(f"Total time (first pass): {time.time() - stime}")

    fast_images = []
    stime = time.time()
    with world_building_unity_bridge(unity_path) as unity_bridge:
        data_iterator = follow_path_data_iterator(unity_bridge,
                                                  world,
                                                  path,
                                                  steps=10,
                                                  pause=-1)
        for pose, image, ranges in data_iterator:
            print({time.time() - stime})
            fast_images.append(image)
            assert min(ranges) < 11.0
            assert min(ranges) > 9.0

    print(f"Total time (second pass): {time.time() - stime}")

    assert len(slow_images) > 10
    assert len(fast_images) > 10

    for sim, fim in zip(slow_images, fast_images):
        assert np.abs(sim - fim).sum() < 1.0
