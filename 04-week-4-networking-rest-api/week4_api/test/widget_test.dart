import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Post Model', () {
    test('fromJson dengan data lengkap', () {
      final json = {
        'userId': 1,
        'id': 2,
        'title': 'Judul',
        'body': 'Isi',
      };
      final post = Post.fromJson(json);
      expect(post.userId, 1);
      expect(post.id, 2);
      expect(post.title, 'Judul');
      expect(post.body, 'Isi');
    });

    test('fromJson dengan field hilang tidak crash', () {
      final post = Post.fromJson({});
      expect(post.userId, 0);
      expect(post.id, 0);
      expect(post.title, '');
      expect(post.body, '');
    });
  });

  group('Comment Model', () {
    test('fromJson dengan field hilang tidak crash', () {
      final comment = Comment.fromJson({});
      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    test('fromJson dengan data lengkap', () {
      final json = {
        'postId': 1,
        'id': 2,
        'name': 'Nama',
        'email': 'email@contoh.com',
        'body': 'Isi komentar',
      };
      final comment = Comment.fromJson(json);
      expect(comment.postId, 1);
      expect(comment.id, 2);
      expect(comment.name, 'Nama');
      expect(comment.email, 'email@contoh.com');
      expect(comment.body, 'Isi komentar');
    });
  });
}