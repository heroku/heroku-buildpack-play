#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh
. ${BUILDPACK_HOME}/bin/common.sh

EXPECTED_VERSION=0.1.5.9

testGetPlayVersionFileMissing()
{  
  capture get_play_version missing.properties

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPlayVersionMissing()
{  
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - another.key another.value
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPlayVersionOnSingleLine_Unix()
{  
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - play ${EXPECTED_VERSION}
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${OUTPUT_DIR}/dependencies.yaml)"

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPlayVersionOnMutipleLines_Unix()
{  
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - something.before 0.0.0
 - play ${EXPECTED_VERSION}
 - something.after 2.2.2
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${OUTPUT_DIR}/dependencies.yaml)"

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml
  
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}


testGetPlayVersionOnSingleLine_Windows()
{  
  sed -e 's/$/\r/' > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - play ${EXPECTED_VERSION}
EOF
  assertEquals "Precondition: Should be a Windows file" "ASCII text, with CRLF line terminators" "$(file -b ${OUTPUT_DIR}/dependencies.yaml)"

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml
  
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPlayVersionOnMutipleLines_Windows()
{  
   sed -e 's/$/\r/' > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - something.before 0.0.0
 - play ${EXPECTED_VERSION}
 - something.after 2.2.2
EOF
  assertEquals "Precondition: Should be a Window file" "ASCII text, with CRLF line terminators" "$(file -b ${OUTPUT_DIR}/dependencies.yaml)"

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPlayVersionOnMutipleLines_PlayMultiple()
{  
    cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 require: 
 - play 1.2.4
 - play -> secure
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals "1.2.4"
}

testGetPlayVersionOnMutipleLines_PlayMultipleBlank()
{  
    cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 require: 
 - play
 - play -> secure
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPlayVersionOnMutipleLines_PlayMultipleNotFirst()
{  
    cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 require: 
 - play -> secure
 - play 1.2.4
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml play

  assertCapturedSuccess
  assertCapturedEquals "1.2.4"
}

testGetPlayVersionOnMutipleLines_PlayMultipleNotFirst_FirstHasVersion()
{  
    cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 require: 
 - play -> secure 1.2.3
 - play 1.2.4
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml play

  assertCapturedSuccess
  assertCapturedEquals "1.2.4"
}

testGetPlayVersionOnMutipleLines_PlayMultipleDiffPropertyName()
{  
    cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 require: 
 - play 1.2.4
 - other -> secure
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals "1.2.4"
}


testGetPlayVersionOnMutipleLines_PlaySingle()
{  
    cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 require: 
 - play 1.2.4
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals "1.2.4"
}

testGetPlayVersionOnMutipleLines_PlaySingleBlank()
{  
    cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 require: 
 - play
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals ""
}


testGetPlayVersionWithSpaces()
{
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - play       ${EXPECTED_VERSION}    
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPlayVersionWithTabs()
{
  sed -e 's/ /\t/g' > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - play       ${EXPECTED_VERSION}    
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPlayVersionWithTrailingLetters()
{
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - play ${EXPECTED_VERSION}zAc
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${OUTPUT_DIR}/dependencies.yaml)"

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}zAc"
}

testGetPlayVersionWithNoSpaces() {
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - play1234
EOF
  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml
  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPlayVersionWithNoValue() {
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - play
EOF
  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml
  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPlayVersionWithNoLeadingDash()
{
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
  play 1234
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPlayVersionWithNoLeadingSpaces()
{
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
- play ${EXPECTED_VERSION}    
EOF

  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPlayVersionWithSimilarNames() {
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - play ${EXPECTED_VERSION}
 - play.new ${EXPECTED_VERSION}new
EOF
  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPlayVersionWithSimilarNameReverseOrder() {
  cat > ${OUTPUT_DIR}/dependencies.yaml <<EOF
 - play.new ${EXPECTED_VERSION}new
 - play ${EXPECTED_VERSION}
EOF
  capture get_play_version ${OUTPUT_DIR}/dependencies.yaml
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}
