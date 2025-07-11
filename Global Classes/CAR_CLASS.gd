extends Node
class_name CAR_CONSTS

signal SeatAvailable
enum SEAT_STATUS{
	OPEN,
	TAKEN}
signal CarEngineOff
enum ENGINE_STATE {
	ON,
	OFF}
signal TransmissionChange
enum CAR_TRANSMISSION_MANUAL {
	M1,
	M2,
	M3,
	M4,
	M5,
	MNeutral,
	MReverse}
enum CAR_TRANSMISSION_AUTO {
	DRIVE,
	REVERSE,
	PARK,
	NEUTRAL,
	D_R_TOGGLE}
