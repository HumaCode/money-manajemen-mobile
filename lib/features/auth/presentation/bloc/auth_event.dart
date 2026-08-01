import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmittedEvent extends AuthEvent {
  final String login;
  final String password;

  const LoginSubmittedEvent({
    required this.login,
    required this.password,
  });

  @override
  List<Object?> get props => [login, password];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}
