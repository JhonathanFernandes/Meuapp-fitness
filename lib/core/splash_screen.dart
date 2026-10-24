/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * wger Workout Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Color(0xFF101010), body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fitness_center, size: 54, color: Color(0xFFC9F31D)), SizedBox(height: 16), Text('MEU FIT', style: TextStyle(color: Color(0xFFC9F31D), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)), SizedBox(height: 18), SizedBox(width: 120, child: LinearProgressIndicator(color: Color(0xFFC9F31D), backgroundColor: Color(0xFF242424)))])));
  }
}
