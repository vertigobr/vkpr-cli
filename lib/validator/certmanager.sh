# -----------------------------------------------------------------------------
# Cert Manager validators
# -----------------------------------------------------------------------------

validateCertManagerEmail() {
  if [[ $1 =~ ^[a-z0-9.]+@[a-z0-9]+\.[a-z]+(\.[a-z]+)?$ ]]; then
    return
  else
    error "Invalid email, specifies your email to issue the certificate."
    exit
  fi
}

validateCertManagerIssuer() {
  if [[  "$1" =~ ^staging|production$ ]]; then
   return 
  else
    error "Invalid issuer, specifies what will be used to issue certificates."
    exit
  fi
}

validateCertManagerIssueSolver() {
  if [[  "$1" =~ ^HTTP01|DNS01$ ]]; then
   return 
  else
    error "Invalid issue Solver, specifies the type of challenge you will use to issue the certificate."
    exit
  fi
}
