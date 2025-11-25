{
  environment-target = "dev";
  latest_cvault = null;
  rotate_keys = false;
  actions_folder = ./scripts/actions;
  share_holder_keys_folder = ./share_holders_keys;
  actions_in_order = [
    #"create-root-CA"
    #"create-intermediate-CA"
    #"sign-csr"
    #"revoke-certificate"
  ];
}
