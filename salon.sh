#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"
echo -e "\n~~~ Schedule A Salon Appointment ~~~\n"

SERVICE_MENU() {
  # get services
  RETURN_SERVICES=$($PSQL "SELECT * FROM services ORDER BY service_id;")
  echo "$RETURN_SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME" | sed -r 's/^ *| *$//g'
  done
  # read input
  read SERVICE_ID_SELECTED
  # check if input is an integer
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    # input is not an integer
    echo -e "\nEnter Only The Number Which Corresponds To Your Desired Service:\n"
    SERVICE_MENU
  else
    # input is an integer
    RETURN_SELECTED_SERVICE_ID=$($PSQL "Select service_id From services WHERE service_id = $SERVICE_ID_SELECTED")
    # check if input is a valid service_id
    if [[ -z $RETURN_SELECTED_SERVICE_ID ]]
    then 
      # input returned nothing, service_id not valid
      echo -e "\nPlease Enter A Valid Service Number From Below:\n"
      SERVICE_MENU
    fi
  fi
}

CUSTOMER_LOOKUP() {
echo -e "\nPlease Enter Your Phone Number"
read CUSTOMER_PHONE
# check input syntax
if [[ -z $CUSTOMER_PHONE ]]
then
  # input doesn't match expected syntax
  echo -e "\nPlease Enter A Valid 9 Digit Phone Number\nUse Dashes To Seperate\nExample: 000-000-0000"
  CUSTOMER_LOOKUP
else
  # input matches expected syntax
  # get customers information
  RETURN_CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  # if customer doesn't exit
  if [[ -z $RETURN_CUSTOMER_ID ]]
  then
    # get customers name
    echo -e "\nIt looks like this is your first time with us.\n~~~\nnote: press return without entering a name to try another phone number\n~~~\nPlease Enter Your First Name:"
    read CUSTOMER_NAME
    if [[ -z $CUSTOMER_NAME ]]
    then
      # enter another phone number
      CUSTOMER_LOOKUP
     else
      # insert customer information
      INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
      RETURN_CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
      echo -e "\nFrom now on you can schedule services with just your phone number!"
    fi
  else
    # get customers name
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = '$RETURN_CUSTOMER_ID'")

  fi
fi
}

SCHEDULE_SERVICE() {
  echo -e "\nWhat time would you like to get started?"
  read SERVICE_TIME
  if [[ -z $SERVICE_TIME ]]
  then
    SCHEDULE_SERVICE
  else
    SERVICE_NAME=$($PSQL "SELECT name FROM services where service_id = '$RETURN_SELECTED_SERVICE_ID'")
    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES('$RETURN_CUSTOMER_ID', '$SERVICE_ID_SELECTED', '$SERVICE_TIME');")
    echo -e "\nI have put you down for a $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g') at $(echo $SERVICE_TIME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
  fi
}

# select a service from service menu
SERVICE_MENU
# get customer id by phone number
CUSTOMER_LOOKUP
# schedule the service
SCHEDULE_SERVICE
exit
