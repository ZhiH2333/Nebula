class Post {
  final String id;
  final String title;
  final String body;
  final String author;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.createdAt,
  });
}
