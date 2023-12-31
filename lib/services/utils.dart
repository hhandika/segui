String get greeting {
  int hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good morning!';
  } else if (hour < 18) {
    return 'Good afternoon!';
  } else {
    return 'Good evening!';
  }
}

String get greetingIconPack {
  int hour = DateTime.now().hour;
  if (hour < 12) {
    return 'assets/images/sunrise.svg';
  } else if (hour < 18) {
    return 'assets/images/afternoon.svg';
  } else {
    return 'assets/images/night.svg';
  }
}
