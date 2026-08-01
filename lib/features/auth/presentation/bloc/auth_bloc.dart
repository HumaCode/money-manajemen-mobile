import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_manajemen/features/auth/domain/repositories/auth_repository.dart';
import 'package:money_manajemen/features/auth/domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final userModel = await loginUseCase.execute(
        login: event.login,
        password: event.password,
      );
      emit(AuthSuccess(userModel: userModel));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthFailure(errorMessage: message));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final token = await authRepository.getToken();
    if (token != null && token.isNotEmpty) {
      // Token exists
    } else {
      emit(UnauthenticatedState());
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(UnauthenticatedState());
  }
}
