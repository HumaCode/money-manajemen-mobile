import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:money_manajemen/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:money_manajemen/features/auth/domain/usecases/login_usecase.dart';
import 'package:money_manajemen/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:money_manajemen/features/auth/presentation/pages/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoneyFlowApp());
}

class MoneyFlowApp extends StatelessWidget {
  const MoneyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final httpClient = http.Client();
    final authRemoteDataSource = AuthRemoteDataSourceImpl(client: httpClient);
    final authLocalDataSource = AuthLocalDataSourceImpl();
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      localDataSource: authLocalDataSource,
    );
    final loginUseCase = LoginUseCase(authRepository);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            loginUseCase: loginUseCase,
            authRepository: authRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Money Manajemen',
        debugShowCheckedModeBanner: false,
        theme: moneyFlowTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
