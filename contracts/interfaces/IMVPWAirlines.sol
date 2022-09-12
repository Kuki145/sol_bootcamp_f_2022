// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IMVPWAirlines {
    /// @notice A struct containing the number of tickets a person has reserved
    struct Reservation {
        uint8 firstClassSeatsReserved;
        uint8 economyClassSeatsReserved;
    }

    /// @notice A struct containing flight information
    struct Flight {
        uint256 departureTime;
        uint256 economyClassPrice;
        uint256 firstClassPrice;
        uint32 airplaneID;
        mapping(address => Reservation) reservations;
        uint16 economyClassSeatsAvailable;
        uint16 firstClassSeatsAvailable;
    }

    /// @notice A struct containing information about an airplane
    /// @dev isOnHold uses the _false_ value as the default for more efficiency, isRegistered is used to check if the plane exists
    struct Airplane {
        uint16 economyClassCapacity;
        uint16 firstClassCapacity;
        bool isOnHold;
        bool isRegistered;
    }

    /// @notice Event denoting that a new Airplane has been registered
    /// @param airplaneID The uint32 ID of the airplane
    /// @param economyClassCapacity The maximum number of tickets available for the economy class
    /// @param firstClassCapacity The maximum number of tickets available for the economy class
    event AirplaneRegistered(
        uint32 airplaneID,
        uint16 economyClassCapacity,
        uint16 firstClassCapacity
    );

    /// @notice Event denoting that a new flight has been created/announced
    /// @param airplaneID The uint32 ID of the airplane
    /// @param flightID The uint32 ID of the flight
    /// @param departureTime The time of departure
    /// @param destination The destination of the flight
    event FlightAnnounced(
        uint32 indexed airplaneID,
        uint256 indexed flightID,
        uint256 departureTime,
        uint256 economyClassPrice,
        uint256 firstClassPrice,
        uint256 economyClassCapacity,
        uint256 firstClassCapacity,
        string destination
    );

    /// @notice Event denoting that an amount of tickets was purchased
    /// @param flightID The uint256 ID of the flight
    /// @param purchaser The address of the ticket purchaser
    /// @param numberOfEconomyClassSeats The number of economy class seats which were purchased
    /// @param numberOfFirstClassSeats The number of firts class seats which were purchased
    event TicketsPurchased(
        uint256 indexed flightID,
        address indexed purchaser,
        uint256 numberOfEconomyClassSeats,
        uint256 numberOfFirstClassSeats
    );

    /// @notice Event denoting that an amount of tickets was cancelled
    /// @param flightID The uint256 ID of the flight
    /// @param purchaser The address of the ticket purchaser
    /// @param numberOfEconomyClassSeats The number of economy class seats which were cancelled
    /// @param numberOfFirstClassSeats The number of firts class seats which were cancelled
    event TicketsCancelled(
        uint256 indexed flightID,
        address indexed purchaser,
        uint256 numberOfEconomyClassSeats,
        uint256 numberOfFirstClassSeats
    );

    /// @notice Function which new owner calls to confirm the ownership transfer
    function acceptOwnership() external;

    /// @notice Function for registering a new airplane
    /// @dev Maximum of 2**32 - 1 airplaes is allowed
    /// @param _airplaneID The uint32 ID of the airplane
    /// @param _economyClassCapacity The maximum number of tickets available for the economy class
    /// @param _firstClassCapacity The maximum number of tickets available for the economy class
    function registerNewAirplane(
        uint32 _airplaneID,
        uint16 _economyClassCapacity,
        uint16 _firstClassCapacity
    ) external;

    /// @notice Puts the airplane on hold, preventing flights for this airplane to be announced
    /// @param _airplaneID The uint32 ID of the airplane
    function holdAirplane(uint32 _airplaneID) external;

    /// @notice Puts the airplane off holding, allowing flights for this airplane to be announced
    /// @param _airplaneID The uint32 ID of the airplane
    function releaseAirplane(uint32 _airplaneID) external;

    /// @notice Announces a new flight
    /// @param _flightID The uint256 ID of the flight
    /// @param _departureTime The uint256 ID time of departure of the flight
    /// @param _economyClassPrice The uint256 price for the economy class ticket for the flight
    /// @param _firstClassPrice The uint256 price for the first class ticket for the flight
    /// @param _airplaneID The uint32 ID of the airplane used for the flight
    /// @param _destination The destination of the flight
    function announceNewFlight(
        uint256 _flightID,
        uint256 _departureTime,
        uint256 _economyClassPrice,
        uint256 _firstClassPrice,
        uint32 _airplaneID,
        string calldata _destination
    ) external;

    /// @notice Return all seats for a flight
    /// @param _flightID The uint256 ID of the flight
    /// @return economyClassSeatsAvailable The number of economy class seats available for purchase
    /// @return firstClassSeatsAvailable The number of first class seats available for purchase
    function getSeatsAvalailable(uint256 _flightID)
        external
        view
        returns (
            uint16 economyClassSeatsAvailable,
            uint16 firstClassSeatsAvailable
        );

    /// @notice Returns the flight capacity of economy and first class seats
    /// @param _flightID The uint256 ID of the flight
    /// @return economyClassCapacity The maximum number of economy class seats that can be created
    /// @return firstClassCapacity The maximum number of first class seats that can be created
    function getFlightCapacity(uint256 _flightID)
        external
        view
        returns (uint16 economyClassCapacity, uint16 firstClassCapacity);

    /// @notice Function for reserving new tickets
    /// @param _flightID The uint256 ID of the flight
    /// @param _numberOfEconomyClassSeats The uint8 number of economy class tickets the user wants to purchase
    /// @param _numberOfFirstClassSeats The uint8 number of first class tickets the user wants to purchase
    function bookTickets(
        uint256 _flightID,
        uint8 _numberOfEconomyClassSeats,
        uint8 _numberOfFirstClassSeats
    ) external;

    /// @notice Function for cancelling reserved tickets
    /// @param _flightID The uint256 ID of the flight
    /// @param _numberOfEconomyClassSeats The uint8 number of economy class tickets the user wants to cancel
    /// @param _numberOfFirstClassSeats The uint8 number of first class tickets the user wants to cancel
    function cancelTickets(
        uint256 _flightID,
        uint8 _numberOfEconomyClassSeats,
        uint8 _numberOfFirstClassSeats
    ) external;
}
