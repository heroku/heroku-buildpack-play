#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh
. ${BUILDPACK_HOME}/bin/common.sh

EXPECTED_VERSION=0.1.5.9

testGetPropertyFileMissing()
{  
  capture get_property missing.properties application.version

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPropertyMissing()
{  
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
 - another.key another.value
EOF

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPropertyOnSingleLine_Unix()
{  
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
 - application.version ${EXPECTED_VERSION}
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${OUTPUT_DIR}/sample.properties)"

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPropertyOnMutipleLines_Unix()
{  
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
 - something.before 0.0.0
 - application.version ${EXPECTED_VERSION}
 - something.after 2.2.2
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${OUTPUT_DIR}/sample.properties)"

  capture get_property ${OUTPUT_DIR}/sample.properties application.version
  
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}


testGetPropertyOnSingleLine_Windows()
{  
  sed -e 's/$/\r/' > ${OUTPUT_DIR}/sample.properties <<EOF
 - application.version ${EXPECTED_VERSION}
EOF
  assertEquals "Precondition: Should be a Windows file" "ASCII text, with CRLF line terminators" "$(file -b ${OUTPUT_DIR}/sample.properties)"

  capture get_property ${OUTPUT_DIR}/sample.properties application.version
  
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPropertyOnMutipleLines_Windows()
{  
   sed -e 's/$/\r/' > ${OUTPUT_DIR}/sample.properties <<EOF
 - something.before 0.0.0
 - application.version ${EXPECTED_VERSION}
 - something.after 2.2.2
EOF
  assertEquals "Precondition: Should be a Window file" "ASCII text, with CRLF line terminators" "$(file -b ${OUTPUT_DIR}/sample.properties)"

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPropertyWithSpaces()
{
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
 - application.version       ${EXPECTED_VERSION}    
EOF

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPropertyWithTabs()
{
  sed -e 's/ /\t/g' > ${OUTPUT_DIR}/sample.properties <<EOF
 - application.version       ${EXPECTED_VERSION}    
EOF

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPropertyWithDashAndLetters()
{
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
 - application.version -${EXPECTED_VERSION}-zAc-
EOF
  assertEquals "Precondition: Should be a UNIX file" "ASCII text" "$(file -b ${OUTPUT_DIR}/sample.properties)"

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedEquals "-${EXPECTED_VERSION}-zAc-"
}

testGetPropertyWithNoSpaces() {
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
 - application.version1234
EOF
  capture get_property ${OUTPUT_DIR}/sample.properties application.version
  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPropertyWithNoValue() {
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
 - application.version
EOF
  capture get_property ${OUTPUT_DIR}/sample.properties application.version
  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPropertyWithNoLeadingDash()
{
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
  application.version 1234
EOF

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedEquals ""
}

testGetPropertyWithNoLeadingSpaces()
{
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
- application.version ${EXPECTED_VERSION}    
EOF

  capture get_property ${OUTPUT_DIR}/sample.properties application.version

  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}"
}

testGetPropertyWithSimilarNames() {
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
 - application.version ${EXPECTED_VERSION}
 - application.version.new ${EXPECTED_VERSION}-new
EOF
  capture get_property ${OUTPUT_DIR}/sample.properties application.version.new
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}-new"
}

testGetPropertyWithSimilarNameReverseOrder() {
  cat > ${OUTPUT_DIR}/sample.properties <<EOF
 - application.version.new ${EXPECTED_VERSION}-new
 - application.version ${EXPECTED_VERSION}
EOF
  capture get_property ${OUTPUT_DIR}/sample.properties application.version.new
  assertCapturedSuccess
  assertCapturedEquals "${EXPECTED_VERSION}-new"
}
