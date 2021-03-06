#!/bin/bash
#

# pi_stepper.sh
#
# Script for controlling a single 28BYJ-48 stepper
# motor with Raspberry pi GPIO pins.
#
# (c) 2020 Jason Charcalla
#     April 12 2020


# Exit Codes:
#   0 all good
#   1 Generic fail
#   2 Bad mode selected
#   3 Invalid argument count

# Set default durration of sleep between steps
STEP_SLEEP=0.0015

print_usage() {
PROG_NAME=$(basename "$0")
cat <<EOF
        # All flags except "-p" are required!
        #
        # Usage: ${PROG_NAME} -d forward -s 64 -m single -1 12 -2 16 -3 20 -4 21 -p 0.0015

        # Standard options:
          -d Step motor direction (forward, reverse)
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
EOF
}

if [ "$#" -lt 14 ]; then
            echo "ERROR: Missing arguments!"
	    print_usage
            exit 3
fi

while getopts h?d:s:m:p:1:2:3:4: arg ; do
      case $arg in
        p) STEP_SLEEP="${OPTARG}" ;;
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
STEPPER_PINS=("${PIN0}" "${PIN1}" "${PIN2}" "${PIN3}")
FORWARD_PINS=(${STEPPER_PINS[*]})
REVERSE_PINS=("${PIN3}" "${PIN2}" "${PIN1}" "${PIN0}")

# A function for initializing the GPIO pins for the stepper motor
stepper_init () {
  for pin in "${STEPPER_PINS[@]}"
  do
	  # Export GPIO pin if not already done
          if [ ! -L /sys/class/gpio/gpio"${pin}" ]
          then
 	    echo "${pin}" > /sys/class/gpio/export
          fi
	  # Set pin to output
	  echo "out" > /sys/class/gpio/gpio"${pin}"/direction
	  # Set pin to low
	  echo "0" > /sys/class/gpio/gpio"${pin}"/value
  done
}

# A function to disable the GPIO pins whne we are done.
stepper_deactivate () {
  for pin in "${STEPPER_PINS[@]}"
  do
          # Export GPIO pin if not already done
          if [ -L /sys/class/gpio/gpio"${pin}" ]
          then
            echo "${pin}" > /sys/class/gpio/unexport
          fi
}

# Single step mode
single_step () {
  # initialze a counter for the while loop itteration
  i=0
  # Set the fist pin to fire, this is in refrence to the STEPPER_PINS array
  fire_pin=0
  while [ ${i} -le "${STEP_COUNT}" ]
  do
	  # Energize pin
	  ## echo "fireing pin \"${ORDERED_PINS[${fire_pin}]}\""
          echo "1" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin}]}"/value
	  # Sleep
          sleep ${STEP_SLEEP}
	  # De-energize pin
	  ## echo "de-energize pin \"${ORDERED_PINS[${fire_pin}]}\""
          echo "0" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin}]}"/value

	  if [ ${fire_pin} -eq 3 ]
	  then
		  # Reset back to the first pin in the array
		  fire_pin=0
	  else
		  fire_pin=$(( fire_pin + 1 ))
          fi
	  i=$(( i + 1 ))
  done
}



# Halfstep mode

half_step () {
  # initialze a counter for the while loop itteration
  i=0
  # Another counter to determine if we are on an even or odd step
  even_odd=0
  # Set the fist pin to fire, this is in refrence to the STEPPER_PINS array
  fire_pin_a=0
  fire_pin_b=1
  while [ ${i} -le "${STEP_COUNT}" ]
  do
          # On even steps we energize one pin, on odd we energize two.
          # fire pins are only +1 on odd steps.
          if [ ${even_odd} -eq 0 ]
          then
            # Energize pin
            ## echo "fireing pin ${ORDERED_PINS[${fire_pin_a}]}"
            echo "1" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_a}]}"/value
            sleep ${STEP_SLEEP}
            # De-energize pin
            ## echo "de-energize pin ${ORDERED_PINS[${fire_pin_a}]}"
            echo "0" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_a}]}"/value
          else
            # Energize pin
            ## echo "fireing pins ${ORDERED_PINS[${fire_pin_a}]} and ${ORDERED_PINS[${fire_pin_b}]}"
            echo "1" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_a}]}"/value
            echo "1" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_b}]}"/value
            # Sleep
            sleep ${STEP_SLEEP}
            # De-energize pin
            ## echo "de-energize pins ${ORDERED_PINS[${fire_pin_a}]} and ${ORDERED_PINS[${fire_pin_b}]}"
            echo "0" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_a}]}"/value
            echo "0" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_b}]}"/value

            if [ ${fire_pin_a} -eq 3 ]
            then
                  # Reset back to the first pin in the array
                  fire_pin_a=0
            else
                  fire_pin_a=$(( fire_pin_a + 1 ))
            fi

            if [ ${fire_pin_b} -eq 3 ]
            then
                  # Reset back to the first pin in the array
                  fire_pin_b=0
            else
                  fire_pin_b=$(( fire_pin_b + 1 ))
            fi
          fi

          if [ ${even_odd} -eq 1 ]
          then
                  # Reset back to zero
                  even_odd=0
          else
                  even_odd=1
          fi
          i=$(( i + 1 ))
  done
}

# Fullstep mode
full_step () {
  # initialze a counter for the while loop itteration
  i=0
  # Set the fist pin to fire, this is in refrence to the STEPPER_PINS array
  fire_pin_a=0
  fire_pin_b=3
  while [ ${i} -le "${STEP_COUNT}" ]
  do
          # Energize pin
          ## echo "fireing pins ${ORDERED_PINS[${fire_pin_a}]} and ${ORDERED_PINS[${fire_pin_b}]}"
          echo "1" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_a}]}"/value
          echo "1" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_b}]}"/value
          # Sleep
          sleep ${STEP_SLEEP}
          # De-energize pin
          ## echo "de-energize pins ${ORDERED_PINS[${fire_pin_a}]} and ${ORDERED_PINS[${fire_pin_b}]}"
          echo "0" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_a}]}"/value
          echo "0" > /sys/class/gpio/gpio"${ORDERED_PINS[${fire_pin_b}]}"/value

          if [ ${fire_pin_a} -eq 3 ]
          then
                  # Reset back to the first pin in the array
                  fire_pin_a=0
          else
                  fire_pin_a=$(( fire_pin_a + 1 ))
          fi

          if [ ${fire_pin_b} -eq 3 ]
          then
                  # Reset back to the first pin in the array
                  fire_pin_b=0
          else
                  fire_pin_b=$(( fire_pin_b + 1 ))
          fi
          i=$(( i + 1 ))
  done
}

# Run the init function.
stepper_init

# Set the direction to rotate the motor.
if [ "${DIRECTION}" == "reverse" ]
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
   exit 2 ;;
esac

exit 0
