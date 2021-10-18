import itertools
import numpy as np
import shapely.geometry
import shapely.ops


def full_simplify_shapely_polygon(poly):
    """This function simplifies a polygon, removing any colinear points.
    Though Shapely has this functionality built-in, it won't remove the
    "start point" of the polygon, even if it's colinear."""

    if isinstance(poly, shapely.geometry.MultiPolygon) or isinstance(
            poly, shapely.geometry.GeometryCollection):
        return shapely.geometry.MultiPolygon(
            [full_simplify_shapely_polygon(p) for p in poly])

    poly = poly.simplify(0.001, preserve_topology=True)
    # The final point is removed, since shapely will auto-close polygon
    points = np.array(poly.exterior.coords)
    if (points[-1] == points[0]).all():
        points = points[:-1]

    def is_colinear(p1, p2, p3, tol=1e-6):
        """Checks if the area formed by a triangle made of the three points
        is less than a tolerance value."""
        return abs(p1[0] * (p2[1] - p3[1]) + p2[0] * (p3[1] - p1[1]) + p3[0] *
                   (p1[1] - p2[1])) < tol

    if is_colinear(points[0], points[1], points[-1]):
        poly = shapely.geometry.Polygon(points[1:])

    return poly


def obstacles_and_boundary_from_occupancy_grid(grid, resolution):
    print("Computing obstacles")
    print(resolution)

    known_space_poly = shapely.geometry.Polygon()

    polys = []
    for index, val in np.ndenumerate(grid):
        if val < 0.5:
            continue

        y, x = index
        y *= resolution
        x *= resolution
        y -= 0.5 * resolution
        x -= 0.5 * resolution
        r = resolution
        polys.append(
            shapely.geometry.Polygon([(x, y), (x + r, y), (x + r, y + r),
                                      (x, y + r)
                                      ]).buffer(0.001 * resolution, 0))

    known_space_poly = shapely.ops.cascaded_union(polys)

    def get_obstacles(poly):
        if isinstance(poly, shapely.geometry.MultiPolygon):
            return list(
                itertools.chain.from_iterable([get_obstacles(p)
                                               for p in poly]))

        obstacles = [
            full_simplify_shapely_polygon(shapely.geometry.Polygon(interior))
            for interior in list(poly.interiors)
        ]

        # Simplify the polygon
        boundary = full_simplify_shapely_polygon(poly)

        obstacles.append(boundary)

        return obstacles

    obs = get_obstacles(known_space_poly)
    obs.sort(key=lambda x: x.area, reverse=True)
    return obs[1:], obs[0]
