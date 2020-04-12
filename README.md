# pi_stepper
Raspberry pi 28BYJ-48/ULN2003 stepper motor control in bash.

# Usage:
```
        # All flags are required!
        #
        # Usage: ${PROG_NAME} -d forward -s 64 -m single -1 12 -2 16 -3 20 -4 21

        # Standard options:
          -d Step motor direction
	  -s Number of steps to make
	  -m Stepper mode (single, half, full)

        # ULN2003 controller input options:
        # Each of the four inputs on the stepper motor
        # controller must be connected to a Raspberry
        # pi GPIO pin. Define those pins here.
          -1 Controller IN1 set to GPIO pin number.  
          -2 Controller IN2 set to GPIO pin number.  
          -3 Controller IN3 set to GPIO pin number.  
          -4 Controller IN4 set to GPIO pin number. 
```
