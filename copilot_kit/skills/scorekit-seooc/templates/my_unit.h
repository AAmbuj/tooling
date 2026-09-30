/********************************************************************************
 * Copyright (c) <YEAR> <COPYRIGHT HOLDER>
 *
 * SPDX-License-Identifier: Apache-2.0
 ********************************************************************************/
// Destination: src/my_unit.h
#pragma once

class MyUnit {
public:
  int DoWork();

private:
  int calls_{0};
};
