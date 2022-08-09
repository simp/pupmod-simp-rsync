# @summary Validator for rsync::server::auth_users
# 
type Rsync::Auth_users = Variant[
    Array[String[1]], 
    Hash[String[1], Optional[String]]
  ]
