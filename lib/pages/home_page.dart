import 'package:flutter/material.dart';
import 'package:neonnekko/auth/auth_service.dart'; // To allow Sign Out

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Placeholder for the Home/Dashboard content
  // Based on wireframe image_07d0b5.png
  @override
  Widget build(BuildContext context) {
    // Access the Auth Service to allow sign out for testing
    final authService = AuthService(); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeonNeko'),
        centerTitle: true,
        // Menu Icon on the left
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // Filter Icon on the right
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.filter_list),
          ),
        ],
      ),
      // Placeholder for the navigation drawer (based on wireframe)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Navigation'),
            ),
            ListTile(title: const Text('Home'), onTap: () => Navigator.pop(context)),
            ListTile(title: const Text('Profile'), onTap: () => { /* Navigate to Profile */ }),
            ListTile(title: const Text('WishList'), onTap: () => { /* Navigate to WishList */ }),
            ListTile(title: const Text('WatchList'), onTap: () => { /* Navigate to WatchList */ }),
            ListTile(title: const Text('Search'), onTap: () => { /* Navigate to Search */ }),
            const Divider(),
            ListTile(
              title: const Text('Sign Out'),
              onTap: () async {
                await authService.signOut();
                // Close the drawer and handle navigation will be done by AuthGate
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder content based on your wireframe image_07d0b5.png
            Text('Trending', style: Theme.of(context).textTheme.headlineMedium),
            _buildPosterRow(),
            const SizedBox(height: 16),
            
            Text('Upcoming', style: Theme.of(context).textTheme.headlineMedium),
            _buildPosterRow(),
            const SizedBox(height: 16),

            Text('Currently Watching', style: Theme.of(context).textTheme.headlineMedium),
            _buildPosterGrid(),
            const SizedBox(height: 16),
            
            Text('WishList: Priority Order', style: Theme.of(context).textTheme.headlineMedium),
            _buildPosterGrid(),
          ],
        ),
      ),
    );
  }

  // Helper widget to build a row of posters (3 items)
  Widget _buildPosterRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(3, (index) => _buildPosterCard()),
        ),
        TextButton(onPressed: () {}, child: const Text('Show all')),
      ],
    );
  }
  
  // Helper widget to build a grid of posters (6 items)
  Widget _buildPosterGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.5, // Adjust for poster height
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildPosterCard(),
    );
  }

  // Helper widget for a single poster card
  Widget _buildPosterCard() {
    return const SizedBox(
      width: 100, // Fixed width for placeholder
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 0.7, // Portrait poster aspect ratio
            child: Placeholder(color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text('anime/movie title', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}