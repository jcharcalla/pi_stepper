#!/bin/bash

## Sure it can be done in python, but wheres the fun in that.
##
## pass in all pins, location file, step width, and forward/reverse through arguments

print_usage() {
cat <<EOF
        Usage: ${PROGNAME}
        -f Step motor forward.
        -p Step motor in reverse.
	-s Number of steps to make
	-m Stepper mode (single, half, full)
EOF
exit 1
}

while getopts h?frs:m: arg ; do
      case $arg in
        f) DIRECTION="forward" ;;
        r) DIRECTION="reverse" ;;
        s) STEP_COUNT="${OPTARG}" ;;
        m) MODE="${OPTARG}" ;;
        h|\?) print_usage; exit ;;
      esac
done

PIN0=12
PIN1=16
PIN2=20
PIN3=21


# Create an array with the pins for each stepper motor.
STEPPER_PINS=(${PIN0} ${PIN1} ${PIN2} ${PIN3})
FORWARD_PINS=(${STEPPER_PINS[*]})
REVERSE_PINS=(${PIN3} ${PIN2} ${PIN1} ${PIN0})

# A function for initializing the GPIO pins for each stepper motor
stepper_init () {
  for pin in ${STEPPER_PINS[@]}
  do
	  ### TODO: Check if this has already been exported
	  # Export pin
	  echo "${pin}" > /sys/class/gpio/export
	  # Set pin to output
	  echo "out" > /sys/class/gpio/gpio${pin}/direction
	  # Set pin to low
	  echo "0" > /sys/class/gpio/gpio${pin}/value
	  #### TODO: Down here we should add something to aling the motor
  done
}

stepper_init

if [ ${DIRECTION} == "reverse" ]
then
  ORDERED_PINS=(${REVERSE_PINS[*]})
else
  ORDERED_PINS=(${FORWARD_PINS[*]})
fi

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
          sleep 0.0015
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

## TODO: case statement around this
single_step


# TODO: Halfstep

# TODO: Fullstep

