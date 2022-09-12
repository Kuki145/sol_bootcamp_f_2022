// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IMVPWAirlines.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MVPWAirlines is Ownable, IMVPWAirlines {
    error EmptyAddress();

    error Unauthorized();

    error AirplaneIDExists(uint32 airplaneID);

    error FlightIDExists(uint256 flightID);

    error InvalidDepartureTime(uint256 departureTime);

    error AirplaneOnHold();

    error AirplaneNotFound();

    error FlightNotFound();

    error NoTicketsChosen();

    error TooManyTicketsChosen();

    error MaximumCapacityReached();

    error AllowanceNotSet();

    error CancellationUnderflow();

    error InsufficientBalance();

    address public pendingOwner;
    address public tokenAddress;

    mapping(uint256 => Flight) public flights;
    mapping(uint32 => Airplane) public airplanes;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    /// @inheritdoc IMVPWAirlines
    function registerNewAirplane(
        uint32 _airplaneID,
        uint16 _economyClassCapacity,
        uint16 _firstClassCapacity
    ) external onlyOwner {
        Airplane storage airplane = airplanes[_airplaneID];

        if (airplane.isRegistered) {
            revert AirplaneIDExists(_airplaneID);
        }

        airplane.economyClassCapacity = _economyClassCapacity;
        airplane.firstClassCapacity = _firstClassCapacity;
        airplane.isRegistered = true;

        emit AirplaneRegistered(
            _airplaneID,
            _economyClassCapacity,
            _firstClassCapacity
        );
    }

    /// @inheritdoc IMVPWAirlines
    function holdAirplane(uint32 _airplaneID) external onlyOwner {
        airplanes[_airplaneID].isOnHold = true;
    }

    /// @inheritdoc IMVPWAirlines
    function releaseAirplane(uint32 _airplaneID) external onlyOwner {
        airplanes[_airplaneID].isOnHold = false;
    }

    /// @inheritdoc IMVPWAirlines
    function announceNewFlight(
        uint256 _flightID,
        uint256 _departureTime,
        uint256 _economyClassPrice,
        uint256 _firstClassPrice,
        uint32 _airplaneID,
        string calldata _destination
    ) external onlyOwner {
        Flight storage flight = flights[_flightID];
        if (flight.departureTime != 0) {
            revert FlightIDExists(_flightID);
        }

        if (_departureTime < block.timestamp) {
            revert InvalidDepartureTime(_departureTime);
        }

        Airplane memory airplane = airplanes[_airplaneID];

        if (!airplane.isRegistered) {
            revert AirplaneNotFound();
        }

        if (airplane.isOnHold) {
            revert AirplaneOnHold();
        }

        flight.departureTime = _departureTime;
        flight.economyClassPrice = _economyClassPrice;
        flight.firstClassPrice = _firstClassPrice;
        flight.airplaneID = _airplaneID;
        flight.economyClassSeatsAvailable = airplane.economyClassCapacity;
        flight.firstClassSeatsAvailable = airplane.firstClassCapacity;

        emit FlightAnnounced(
            _airplaneID,
            _flightID,
            _departureTime,
            _economyClassPrice,
            _firstClassPrice,
            airplane.economyClassCapacity,
            airplane.firstClassCapacity,
            _destination
        );
    }

    /// @inheritdoc IMVPWAirlines
    function bookTickets(
        uint256 _flightID,
        uint8 _numberOfEconomyClassSeats,
        uint8 _numberOfFirstClassSeats
    ) external {
        if (_numberOfFirstClassSeats == 0 && _numberOfEconomyClassSeats == 0) {
            revert NoTicketsChosen();
        }

        Flight storage flight = flights[_flightID];
        Reservation storage reservation = flight.reservations[msg.sender];

        if (
            reservation.economyClassSeatsReserved +
                reservation.firstClassSeatsReserved +
                _numberOfEconomyClassSeats +
                _numberOfFirstClassSeats >
            4
        ) {
            revert TooManyTicketsChosen();
        }

        uint256 totalCost = _numberOfEconomyClassSeats *
            flight.economyClassPrice;
        totalCost += _numberOfFirstClassSeats * flight.firstClassPrice;

        // Check allowance
        IERC20 tokenContract = IERC20(tokenAddress);
        if (tokenContract.allowance(msg.sender, address(this)) < totalCost) {
            revert AllowanceNotSet();
        }

        if (
            flight.economyClassSeatsAvailable < _numberOfEconomyClassSeats ||
            flight.firstClassSeatsAvailable < _numberOfFirstClassSeats
        ) {
            revert MaximumCapacityReached();
        }

        flight.economyClassSeatsAvailable -= _numberOfEconomyClassSeats;
        flight.firstClassSeatsAvailable -= _numberOfFirstClassSeats;

        reservation.economyClassSeatsReserved += _numberOfEconomyClassSeats;
        reservation.firstClassSeatsReserved += _numberOfFirstClassSeats;

        // Transfer tokens
        tokenContract.transferFrom(msg.sender, address(this), totalCost);
    }

    /// @inheritdoc IMVPWAirlines
    function cancelTickets(
        uint256 _flightID,
        uint8 _numberOfEconomyClassSeats,
        uint8 _numberOfFirstClassSeats
    ) external {
        Flight storage flight = flights[_flightID];
        Reservation storage reservation = flight.reservations[msg.sender];

        if (
            _numberOfFirstClassSeats > reservation.firstClassSeatsReserved ||
            _numberOfEconomyClassSeats > reservation.economyClassSeatsReserved
        ) {
            revert CancellationUnderflow();
        }

        flight.economyClassSeatsAvailable += _numberOfEconomyClassSeats;
        flight.firstClassSeatsAvailable += _numberOfFirstClassSeats;

        reservation.economyClassSeatsReserved -= _numberOfEconomyClassSeats;
        reservation.firstClassSeatsReserved -= _numberOfFirstClassSeats;

        if (block.timestamp + 1 days < flight.departureTime) {
            uint256 refundAmount = _numberOfFirstClassSeats *
                flight.firstClassPrice;
            refundAmount +=
                _numberOfEconomyClassSeats *
                flight.economyClassPrice;

            if (block.timestamp + 2 days > flight.departureTime) {
                refundAmount = (refundAmount / 5) * 4;
            }

            // Check allowance
            IERC20 tokenContract = IERC20(tokenAddress);
            if (tokenContract.balanceOf(address(this)) < refundAmount) {
                revert InsufficientBalance();
            }

            tokenContract.transfer(msg.sender, refundAmount);
        }

        emit TicketsCancelled(
            _flightID,
            msg.sender,
            _numberOfEconomyClassSeats,
            _numberOfFirstClassSeats
        );
    }

    /// @inheritdoc	IMVPWAirlines
    function acceptOwnership() external {
        if (msg.sender != pendingOwner) {
            revert Unauthorized();
        }

        _transferOwnership(msg.sender);
    }

    /// @inheritdoc IMVPWAirlines
    function getSeatsAvalailable(uint256 _flightID)
        external
        view
        returns (
            uint16 economyClassSeatsAvailable,
            uint16 firstClassSeatsAvailable
        )
    {
        return (
            flights[_flightID].economyClassSeatsAvailable,
            flights[_flightID].firstClassSeatsAvailable
        );
    }

    /// @inheritdoc IMVPWAirlines
    function getFlightCapacity(uint256 _flightID)
        external
        view
        returns (uint16 economyClassCapacity, uint16 firstClassCapacity)
    {
        Airplane memory airplane = airplanes[flights[_flightID].airplaneID];
        return (airplane.economyClassCapacity, airplane.firstClassCapacity);
    }

    /// @notice Function which sets the new owner argument as the pending owner, waiting for their acceptance
    /// @inheritdoc	Ownable
    function transferOwnership(address _newOwner) public override onlyOwner {
        if (_newOwner == address(0)) {
            revert EmptyAddress();
        }
        pendingOwner = _newOwner;
    }
}
