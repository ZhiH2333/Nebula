import '../models/post.dart';

final List<Post> mockPosts = [
  Post(
    id: '1',
    title: 'Hello Nebula',
    body:
        'This is the first post in our generic timeline. Welcome to the start of something new.',
    author: 'Alice',
    authorId: 'mock-alice-id',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  Post(
    id: '2',
    title: 'Flutter Development',
    body:
        'Building UIs with Flutter is fun. The hot reload feature saves so much time.',
    author: 'Bob',
    authorId: 'mock-bob-id',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Post(
    id: '3',
    title: 'Progressive Architecture',
    body:
        'We are building this app step by step. First structure, then polish.',
    author: 'Charlie',
    authorId: 'mock-charlie-id',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Post(
    id: '4',
    title: 'Mock Data is Useful',
    body:
        'Using mock data allows us to focus on UI independent of backend status.',
    author: 'Dave',
    authorId: 'mock-dave-id',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];
