{ pkgs, ... }:
{
  programs.thunderbird.enable = true;
  programs.thunderbird.profiles.default = {
    isDefault = true;
  };

  accounts.email.maildirBasePath = "Mail";

  accounts.email.accounts = {
    enrico = {
      address = "enryco@mailbox.org";
      realName = "Enrico";
      primary = true;
      # mbsync.enable = false;
      # msmtp.enable = false;
      # notmuch.enable = false;
      # neomutt = {
      #   enable = true;
      #   mailboxName = "";
      # };

      maildir = {
        path = "mailbox_org";
      };
      # himalaya.enable = true;

      # folders = {
      #   # TODO
      #   drafts = "";
      # };

      # signature = {
      #   text = '''';
      #   showSignature = "append";
      # };

      userName = "enryco@mailbox.org";
      # Ignored by Thunderbird
      # passwordCommand = "";
      imap = {
        host = "imap.mailbox.org";
        tls.enable = true;
        port = 993;
      };
      smtp = {
        host = "smtp.mailbox.org";
        port = 465;
        tls.enable = true;
      };

      thunderbird.enable = true;
    };

    hyhyve = {
      address = "enrico@hyhyve.com";
      realName = "Enrico";
      primary = false;

      maildir = {
        path = "hyhyve";
      };

      userName = "enrico@hyhyve.com";

      imap = {
        host = "outlook.office365.com";
        tls.enable = true;
        port = 993;
      };

      # ! Needs OAuth2
      smtp = {
        host = "smtp.outlook.com";
        port = 587;
        tls.enable = true;
        tls.useStartTls = true;
      };

      # signature = {
      #   text = '''';
      #   showSignature = "append";
      # };

      thunderbird = {
        enable = true;
        # OAuth2
        settings = id: {
          "mail.server.server_${id}.authMethod" = 10;
          "mail.smtpserver.smtp_${id}.authMethod" = 10;
        };
      };
    };

    binary = {
      address = "enrico@binaryplease.com";
      realName = "Enrico";
      primary = false;

      maildir = {
        path = "binaryplease";
      };

      userName = "enrico@binaryplease.com";

      imap = {
        host = "outlook.office365.com";
        tls.enable = true;
        port = 993;
      };

      # ! Needs OAuth2
      smtp = {
        host = "smtp.outlook.com";
        port = 587;
        tls.enable = true;
        tls.useStartTls = true;
      };

      signature = {
        text = '''';
        showSignature = "append";
      };

      thunderbird = {
        enable = true;
        # OAuth2
        settings = id: {
          "mail.server.server_${id}.authMethod" = 10;
          "mail.smtpserver.smtp_${id}.authMethod" = 10;
        };
      };
    };
  };

}
