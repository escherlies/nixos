# desktop on the company VPN's `wg-ops` tunnel as workstation 10.110.1.3, next
# to the personal VPN's wg0 (modules/wireguard.nix), and serving enrico's
# nightshift stack and voice agent. Both come from binp-nixos-infra
# (`company-vpn-workstation` and `personal-stack`); this file sets only what is
# desktop's own.
#
# The tunnel shows up in NetworkManager and can be disconnected there
# (hideFromNetworkManager stays at the module's default, false);
# `ssh root@desktop systemctl restart wireguard-wg-ops` or a reboot brings it
# back.
{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.binp-nixos-infra.nixosModules.personal-stack ];

  # Public key, for the hub's opsPeers: dO+6umV7K3bj7tIqnVPqZKvyhD71YM5rwlAkNkr0zlE=
  age.secrets."wg-ops-desktop" = {
    file = ../../secrets/wg-ops-desktop.key.age;
    mode = "0400";
  };

  services.company-vpn.client = {
    address = "10.110.1.3";
    privateKeyFile = config.age.secrets."wg-ops-desktop".path;
  };

  services.personal-stack.user = "enrico";

  # Limits sized for desktop's 30 GiB RAM and 8.8 GiB swap. KillMode=process from
  # the module stays, so agent processes outlive an ordinary daemon restart.
  #
  # Measured 2026-11-02 on a transient user unit with KillMode=process,
  # Restart=on-failure, RestartSec=2, MemoryHigh=410M, MemoryMax=512M, TasksMax=128
  # and MemorySwapMax=0. The load was 100 self-restarting 16M workers, 25 s per case.
  # - OOMPolicy=stop (the default): the first 2 kernel OOM kills made systemd stop
  #   the main process. The load kept running. The restarted main process landed in
  #   the same cgroup and was stopped again after about 1 s. End state: 70 processes
  #   left, Result=oom-kill, memory.events oom=16 oom_kill=4 oom_group_kill=0.
  # - OOMPolicy=continue, no MemoryHigh: oom_kill=5373 and the load kept running. A
  #   main process larger than the workers, as the daemon is (RSS 1.3 GB), was
  #   itself the victim: NRestarts=10 in 25 s, load still alive, oom_kill=5530.
  # - OOMPolicy=kill, which this file sets: the first OOM killed 58 processes within
  #   one second, main included, with memory.oom.group=1 and oom_group_kill=1. The
  #   restarted main process ran alone in an empty cgroup: 1 process, about 5 MB.
  #   The cost is that an OOM in this cgroup also kills every running agent.
  # Two more cases, both with OOMPolicy=stop:
  # - MemorySwapMax=infinity, 700M demand: 408M RAM + 309M swap, oom_kill=0. A
  #   kernel OOM kill therefore needs swap to be full first.
  # - Spawn load only: pids.current stopped at 128, pids.events max=527, oom_kill=0.
  #   The load kept running and every spawn by main failed with EAGAIN.
  home-manager.users.${config.services.personal-stack.user}.systemd.user.services.nightshift.Service =
    {
      MemoryHigh = "16G";
      MemoryMax = "20G";
      TasksMax = 8192;
      OOMPolicy = "kill";
    };
}
