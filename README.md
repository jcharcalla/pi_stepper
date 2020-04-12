# pi_stepper
Raspberry pi 28BYJ-48/ULN2003 stepper motor control in bash.

This script written in Bash can be used to control a 
28BYJ-48/ULN2003 stepper motor connected to a Raspberry pi
via four GPIO pins.

Note: You may need to set appropriate permisions on the GPIO 
 device files in /sys/class/gpio/.

# Usage:
```
        # All flags except "-p" are required!
        #
        # Usage: pi_stepper.sh -d forward -s 64 -m single -1 12 -2 16 -3 20 -4 21 -p 0.005

        # Standard options:
          -d Step motor direction
	  -s Number of steps to make
	  -m Stepper mode (single, half, full)
          -p Length of pause or sleep between steps. Defaults to 0.0015, this is helpful for 
             debugging (watching lights) but times >~ "0.1" will not be fast enough for movement.

        # ULN2003 controller input options:
        # Each of the four inputs on the stepper motor
        # controller must be connected to a Raspberry
        # pi GPIO pin. Define those pins here.
          -1 Controller IN1 set to GPIO pin number.  
          -2 Controller IN2 set to GPIO pin number.  
          -3 Controller IN3 set to GPIO pin number.  
          -4 Controller IN4 set to GPIO pin number. 
```
