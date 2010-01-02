ActiveLdap::Base.setup_connection(
                                  :password_block => Proc.new { 'geheim' },
                                  :allow_anonymous => false,
                                  :host => '127.0.0.1',
                                  :base => 'dc=ul',
                                  :bind_dn => 'cn=root,dc=ul'
)

