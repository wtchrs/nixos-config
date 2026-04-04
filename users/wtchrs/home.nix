_:

{
  programs.git = {
    settings = {
      user = {
        name = "wtchrs";
        email = "wtchr_@hotmail.com";
      };
    };

    signing = {
      format = "openpgp";
      key = "9B1A9F6012740F373835804A0F62C02560E9BAF0";
      signByDefault = true;
    };
  };
}
