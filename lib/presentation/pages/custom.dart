import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class TutorApp extends StatelessWidget {
  const TutorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutor Profile',
      theme: ThemeData(
        primaryColor: const Color(0xFF7A72DE),
        scaffoldBackgroundColor: const Color(0xFFF0F0F7),
        fontFamily: 'Poppins',
      ),
      home: const TutorProfileScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Data Models ---
class Tutor {
  final String name;
  final String location;
  final String role;
  final String profileImageUrl;
  final int projectsCount;
  final String ratePerHour;
  final double rating;
  final List<Skill> skills;
  final List<PortfolioItem> portfolio;

  Tutor({
    required this.name,
    required this.location,
    required this.role,
    required this.profileImageUrl,
    required this.projectsCount,
    required this.ratePerHour,
    required this.rating,
    required this.skills,
    required this.portfolio,
  });
}

class Skill {
  final String name;
  final int rating; // out of 5

  Skill({required this.name, required this.rating});
}

class PortfolioItem {
  final String title;
  final String imageUrl;
  final String description;

  PortfolioItem({
    required this.title,
    required this.imageUrl,
    required this.description,
  });
}

// --- Main Profile Screen ---
class TutorProfileScreen extends StatefulWidget {
  const TutorProfileScreen({Key? key}) : super(key: key);

  @override
  _TutorProfileScreenState createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  // --- Mock Data ---
  final Tutor tutor = Tutor(
    name: 'Arissa Rashid',
    location: 'Singapore',
    role: 'UI/UX Designer',
    profileImageUrl:
        'https://images.unsplash.com/photo-1529068755536-a5ade0dcb4e8?q=80&w=2081&auto=format&fit=crop',
    projectsCount: 24,
    ratePerHour: 'SGD20',
    rating: 4.9,
    skills: [
      Skill(name: 'UI/UX Design', rating: 5),
      Skill(name: 'Graphic Design', rating: 4),
      Skill(name: 'Animation', rating: 3),
    ],
    portfolio: [
      PortfolioItem(
        title: 'Scuba Diving Poster',
        imageUrl: 'https://placehold.co/400x600/E2F0CB/333?text=Scuba+Poster',
        description: 'Promotional poster for a local scuba diving school.',
      ),
      PortfolioItem(
        title: 'NFC Payment Graphics',
        imageUrl: 'https://placehold.co/400x400/FFE6E6/333?text=NFC+Payment',
        description: 'Graphics for an NFC payment application.',
      ),
      PortfolioItem(
        title: 'Meditation App UI',
        imageUrl: 'https://placehold.co/400x600/C4D7E0/333?text=Meditation+App',
        description: 'UI/UX design for a calming meditation app.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7A72DE), // Main purple background
      body: SafeArea(
        child: Stack(
          children: [
            // --- Top Bar Icons ---
            _buildTopBar(),

            // --- Main Content Card ---
            // Using AnimationLimiter for staggered animations
            AnimationLimiter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 60,
                ), // Space for top bar and profile pic overlap
                child: DraggableScrollableSheet(
                  initialChildSize: 0.9,
                  minChildSize: 0.85,
                  maxChildSize: 0.9,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 500),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            const SizedBox(
                              height: 70,
                            ), // Space for overlapping profile pic
                            _buildProfileHeader(),
                            const SizedBox(height: 24),
                            const Divider(
                              color: Color(0xFFF0F0F7),
                              thickness: 1,
                            ),
                            const SizedBox(height: 24),
                            _buildStatsSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('Skills'),
                            const SizedBox(height: 16),
                            _buildSkillsSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('Portfolio', showSeeAll: true),
                            const SizedBox(height: 16),
                            _buildPortfolioSection(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // --- Overlapping Profile Picture ---
            _buildProfilePicture(),
          ],
        ),
      ),
    );
  }

  // --- Widget Builder Methods ---

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Icons.arrow_back,
            color: Colors.white.withOpacity(0.9),
            size: 28,
          ),
          Icon(
            Icons.bookmark_border,
            color: Colors.white.withOpacity(0.9),
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10,
        ), // Adjust this to control overlap
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(tutor.profileImageUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Text(
          tutor.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${tutor.location} ${tutor.role}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('${tutor.projectsCount}', 'Projects'),
        _buildStatItem(tutor.ratePerHour, 'Rate / hr'),
        _buildStatItem('${tutor.rating}', 'Rating'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool showSeeAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        if (showSeeAll)
          Text(
            'See All',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      children: tutor.skills
          .map(
            (skill) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      skill.name,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < skill.rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFF7A72DE),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPortfolioSection() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tutor.portfolio.length,
        itemBuilder: (context, index) {
          final item = tutor.portfolio[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
