import 'package:equatable/equatable.dart';
import 'package:money_manajemen/features/auth/data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserModel userModel;

  const AuthSuccess({required this.userModel});

  @override
  List<Object?> get props => [userModel];
}

class AuthFailure extends AuthState {
  final String errorMessage;

  const AuthFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

class UnauthenticatedState extends AuthState {}
