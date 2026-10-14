function fn() {
  // Pick an environment with -Dkarate.env=<name>; defaults to the public demo site
  var env = karate.env || 'demo';

  var config = {
    env: env,
    baseUrl: 'https://automationintesting.online/api',
    // Credentials come from env vars (CI secrets) and fall back to the public demo values
    adminUser: java.lang.System.getenv('ADMIN_USER') || 'admin',
    adminPassword: java.lang.System.getenv('ADMIN_PASSWORD') || 'password'
  };

  karate.configure('connectTimeout', 10000);
  karate.configure('readTimeout', 60000);
  return config;
}
