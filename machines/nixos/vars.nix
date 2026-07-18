{
  timeZone = "Australia/Sydney";
  locale = "en_AU.UTF-8";
  mainArray = "/mnt/user";
  fastArraySync = "/persist/user/sync/";
  serviceConfigRoot = "/persist/opt/services";
  domainName = "nah.bz";
  # must match users.users.share / users.groups.share in machines/nixos/opslag/shares
  shareUser = {
    name = "share";
    uid = 994;
    gid = 993;
  };
}