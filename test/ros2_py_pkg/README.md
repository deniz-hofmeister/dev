# ROS2 Python Package Example

A simple ROS2 Python package with a publisher and subscriber.

## Build

```bash
cd <workspace_dir>
colcon build --packages-select ros2_py_pkg
```

## Run

In one terminal:
```bash
source install/setup.bash
ros2 run ros2_py_pkg publisher
```

In another terminal:
```bash
source install/setup.bash
ros2 run ros2_py_pkg subscriber
```

## Dependencies

- ROS2 Humble
- rclpy
- std_msgs