#!/usr/bin/env bats
# Unit tests for powermod's pure logic. The script returns early when sourced
# (the guard sits just above the MODE= dispatch), so each test sources it fresh
# - bats isolates tests in subshells - and calls its functions directly.

setup() {
  PM="$BATS_TEST_DIRNAME/../powermod"
}

# --- decode_mode: map (platform_profile, EPP) to a ladder-level label --------
# The five known pairs map to named levels; anything else is reported verbatim
# so an unexpected combination is visible rather than silently mislabelled.

@test "decode_mode names the stock PPD levels" {
  source "$PM"
  run decode_mode low-power power;              [ "$output" = "power-saver" ]
  run decode_mode balanced balance_performance; [ "$output" = "balanced" ]
  run decode_mode performance performance;      [ "$output" = "performance" ]
}

@test "decode_mode names the two custom in-between levels" {
  source "$PM"
  run decode_mode low-power balance_power; [ "$output" = "quiet (custom)" ]
  run decode_mode balanced balance_power;  [ "$output" = "snappy (custom)" ]
}

@test "decode_mode reports an unknown pair verbatim" {
  source "$PM"
  run decode_mode performance balance_power
  [ "$output" = "custom (performance / balance_power)" ]
}

@test "decode_mode passes through a missing-knob placeholder" {
  source "$PM"
  run decode_mode "?" "?"
  [ "$output" = "custom (? / ?)" ]
}

# --- VERSION: present and well-formed ----------------------------------------

@test "VERSION is an X.Y.Z string" {
  source "$PM"
  [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}
