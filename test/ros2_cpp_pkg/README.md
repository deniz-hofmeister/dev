# ros2_simple_pkg

A simple ROS2 Humble publisher and subscriber package.

## Description

This package contains a simple publisher that publishes a "Hello, world!" message to the "topic" topic every second, and a subscriber that listens for messages on the same topic.

## Build Instructions

To build this package, you need ROS2 Humble installed. Then:

```bash
# Clone the repository into your ROS2 workspace src directory
cd ~/ros2_ws/src
# ... clone command or copy files ...

# Build the package
cd ~/ros2_ws
colcon build --packages-select ros2_simple_pkg

# Source the setup file
source install/setup.bash
```

## Run Instructions

In one terminal:
```bash
ros2 run ros2_simple_pkg publisher
```

In another terminal:
```bash
ros2 run ros2_simple_pkg subscriber
```

The publisher will output messages like:
```
[INFO] [1678912345.678910] [simple_publisher]: Publishing: 'Hello, world! 0'
[INFO] [1678912346.678910] [simple_publisher]: Publishing: 'Hello, world! 1'
...
```

The subscriber will output messages like:
```
[INFO] [1678912345.689012] [simple_subscriber]: I heard: 'Hello, world! 0'
[INFO] [1678912346.689012] [simple_subscriber]: I heard: 'Hello, world! 1'
...
```