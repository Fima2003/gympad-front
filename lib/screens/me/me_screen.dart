import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/blocs/auth/auth_bloc.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return Center(child: Text('User ID: ${state.userId}'));
        } else if (state is AuthGuest) {
          return Center(
            child: Text('Guest User - Device ID: ${state.deviceId}'),
          );
        } else if (state is AuthUnauthenticated) {
          return const Center(child: Text('Not signed in'));
        } else if (state is AuthLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AuthError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
