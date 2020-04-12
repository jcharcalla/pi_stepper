#!/bin/bash

## Sure it can be done in python, but wheres the fun in that.
##
## pass in all pins, location file, step width, and forward/reverse through arguments
#
# Exit Codes:
#   0 all good
#   1 Generic fail
#   2 Bad mode selected

print_usage() {
PROG_NAME=$(basename "$0")
cat <<EOF
        # All flags are required!
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
EOF
}

while getopts h?d:s:m:1:2:3:4: arg ; do
      case $arg in
        d) DIRECTION="${OPTARG}" ;;
        s) STEP_COUNT="${OPTARG}" ;;
        m) MODE="${OPTARG}" ;;
        1) PIN0=${OPTARG} ;;
        2) PIN1=${OPTARG} ;;
        3) PIN2=${OPTARG} ;;
        4) PIN3=${OPTARG} ;;
        h|\?) print_usage; exit 1;;
      esac
done


# Create an array with the pins for each stepper motor
# and a reverse order array for turning counterclockwise.
STEPPER_PINS=(${PIN0} ${PIN1} ${PIN2} ${PIN3})
FORWARD_PINS=(${STEPPER_PINS[*]})
REVERSE_PINS=(${PIN3} ${PIN2} ${PIN1} ${PIN0})

# Set durration of sleep between steps
STEP_SLEEP=0.0015

# A function for initializing the GPIO pins for the stepper motor
stepper_init () {
  for pin in ${STEPPER_PINS[@]}
  do
	  # Export GPIO pin if not already done
          if [ ! -L /sys/class/gpio/gpio${pin} ]
          then
 	    echo "${pin}" > /sys/class/gpio/export
          fi
	  # Set pin to output
	  echo "out" > /sys/class/gpio/gpio${pin}/direction
	  # Set pin to low
	  echo "0" > /sys/class/gpio/gpio${pin}/value
  done
}

# Single step mode
single_step () {
  # initialze a counter for the while loop itteration
  i=0
  # Set the fist pin to fire, this is in refrence to the STEPPER_PINS array
  fire_pin=0
  while [ ${i} -le ${STEP_COUNT} ]
  do
	  # Energize pin
	  echo "fireing pin ${ORDERED_PINS[${fire_pin}]}"
          echo "1" > /sys/class/gpio/gpio${ORDERED_PINS[${fire_pin}]}/value
	  # Sleep
          sleep ${STEP_SLEEP}
	  # De-energize pin
	  echo "de-energize pin ${ORDERED_PINS[${fire_pin}]}"
          echo "0" > /sys/class/gpio/gpio${ORDERED_PINS[${fire_pin}]}/value

	  if [ ${fire_pin} -eq 3 ]
	  then
		  # Reset back to the first pin in the array
		  fire_pin=0
	  else
		  fire_pin=$(( $fire_pin + 1 ))
          fi
	  i=$(( $i + 1 ))
  done
}



# TODO: Halfstep

# Fullstep mode
full_step () {
  # initialze a counter for the while loop itteration
  i=0
  # Set the fist pin to fire, this is in refrence to the STEPPER_PINS array
  fire_pin_a=0
  fire_pin_b=3
  while [ ${i} -le ${STEP_COUNT} ]
  do
          # Energize pin
          echo "fireing pins ${ORDERED_PINS[${fire_pin_a}]} and ${ORDERED_PINS[${fire_pin_b}]"
          echo "1" > /sys/class/gpio/gpio${ORDERED_PINS[${fire_pin_a}]}/value
          echo "1" > /sys/class/gpio/gpio${ORDERED_PINS[${fire_pin_b}]}/value
          # Sleep
          sleep ${STEP_SLEEP}
          # De-energize pin
          echo "de-energize pins ${ORDERED_PINS[${fire_pin_a}]} and ${ORDERED_PINS[${fire_pin_b}]"
          echo "0" > /sys/class/gpio/gpio${ORDERED_PINS[${fire_pin_a}]}/value
          echo "0" > /sys/class/gpio/gpio${ORDERED_PINS[${fire_pin_b}]}/value

          if [ ${fire_pin_a} -eq 3 ]
          then
                  # Reset back to the first pin in the array
                  fire_pin_a=0
          else
                  fire_pin_a=$(( $fire_pin_a + 1 ))
          fi

          if [ ${fire_pin_b} -eq 3 ]
          then
                  # Reset back to the first pin in the array
                  fire_pin_b=0
          else
                  fire_pin_b=$(( $fire_pin_b + 1 ))
          fi
          i=$(( $i + 1 ))
  done
}

# Run the init function.
stepper_init

# Set the direction to rotate the motor.
if [ ${DIRECTION} == "reverse" ]
then
  ORDERED_PINS=(${REVERSE_PINS[*]})
else
  ORDERED_PINS=(${FORWARD_PINS[*]})
fi

case ${MODE} in
  single)
   single_step ;;
  half)
   half_step ;;
  full)
   full_step ;;
  *)
   echo "ERROR: Invalid mode selected!"
   print_usage
   exit 2
   
esac

exit 0
