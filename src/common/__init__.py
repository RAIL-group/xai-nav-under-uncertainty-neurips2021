"""Some shared classes and functions."""
import math


class Pose(object):
    counter = 0

    def __init__(self, x, y, yaw=0.0):
        self.x = x
        self.y = y
        self.yaw = yaw
        self.index = Pose.counter
        Pose.counter += 1

    def __repr__(self):
        return "<Pose x:%4f, y:%4f, yaw:%4f>" % (self.x, self.y, self.yaw)

    @staticmethod
    def cartesian_distance(pose_a, pose_b):
        return math.sqrt(
            math.pow(pose_a.x - pose_b.x, 2) +
            math.pow(pose_a.y - pose_b.y, 2))

    def __mul__(self, oth):
        return oth.__rmul__(self)

    def __rmul__(self, oth):
        """Define transform out = oth*self. This should be the equivalent
        of adding an additional pose 'oth' to the current pose 'self'.
        This means that, for example, if we have a robot in pose 'self' and
        a motion primitive that ends at 'oth' the position of the end of the
        motion primitive in the world frame is oth*self.
        """

        try:
            x = self.x + math.cos(self.yaw) * oth.x - math.sin(
                self.yaw) * oth.y
            y = self.y + math.cos(self.yaw) * oth.y + math.sin(
                self.yaw) * oth.x
            yaw = (self.yaw + oth.yaw) % (2 * math.pi)
            return Pose(x, y, yaw)
        except AttributeError:
            return Pose(oth * self.x, oth * self.y, self.yaw)
        else:
            raise TypeError(('Type {0} cannot rmul a Pose object.').format(
                type(oth).__name__))
