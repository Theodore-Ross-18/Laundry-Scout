# Laundry Scout

A Flutter application for finding and managing laundry services.

## Getting Started

This project is a Flutter application that can be deployed to multiple platforms including web.

### Local Development

1. Ensure you have Flutter installed on your machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app in debug mode

## Deploying to Vercel

This project is configured to be deployed to Vercel, even though Vercel doesn't natively support Dart/Flutter. The configuration uses a custom build script to compile the Flutter web app and serve it through Vercel.

### Prerequisites

- A [Vercel](https://vercel.com) account
- [Git](https://git-scm.com/) installed on your machine
- Your project pushed to a Git repository (GitHub, GitLab, or Bitbucket)

### Deployment Steps

1. **Push your code to a Git repository**
   - Make sure your code is pushed to a Git repository (GitHub, GitLab, or Bitbucket)
   - Ensure the `.env` file is included in your `.gitignore` to avoid exposing sensitive information

2. **Set up environment variables in Vercel**
   - Log in to your Vercel account
   - Create a new project and link it to your Git repository
   - Go to the project settings and add the following environment variables:
     - `SUPABASE_URL`: Your Supabase URL
     - `SUPABASE_ANON_KEY`: Your Supabase anonymous key

3. **Deploy your project**
   - Vercel will automatically detect the `vercel.json` configuration file
   - The build script (`build.sh`) will be executed to build your Flutter web app
   - Vercel will deploy the built web app to its hosting platform

4. **Verify your deployment**
   - Once the deployment is complete, Vercel will provide you with a URL to access your app
   - Open the URL in a browser to verify that your app is working correctly

### Configuration Files

The following files have been added to enable Vercel deployment:

- `vercel.json`: Configures Vercel to use the custom build script and sets up routing
- `build.sh`: A bash script that installs Flutter, builds the web app, and sets up a simple Node.js server
- Updated `web/index.html`: Modified to ensure proper loading of the Flutter web app

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Vercel Documentation](https://vercel.com/docs)
- [Supabase Documentation](https://supabase.io/docs)
