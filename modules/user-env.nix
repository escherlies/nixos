# Decrypts user.env.age and makes it available at /run/agenix/user-env
# so the shell can source the environment variables.
{ ... }:
{
  age.secrets.user-env = {
    file = ../secrets/user.env.age;
    owner = "enrico";
    mode = "0400";
  };
}
