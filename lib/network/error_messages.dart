const Map<String, String> kConnectionErrorMessages = {
  // Server-supplied codes
  'not_found': '[ERROR] no such room',
  'room_full': '[ERROR] room is full',
  'bad_message': '[ERROR] invalid code',
  'bad_request': '[ERROR] bad request',
  'cannot_join_own': "[ERROR] that's your own code",
  'already_in_room': '[ERROR] already in a room',
  'not_in_room': '[ERROR] not in a room',
  'not_paired': '[ERROR] not paired with a peer',
  // Client-side connection codes
  'connection_failed': '[ERROR] could not reach server',
  'connection_error': '[ERROR] connection error',
  'connection_lost': '[ERROR] connection lost',
  'connect_timeout': '[ERROR] connection timed out',
};

String describeConnectionError(String? code) =>
    kConnectionErrorMessages[code] ?? '[ERROR] connection failed';
