import 'package:flutter_test/flutter_test.dart';
import 'package:work_hub/features/job/domain/models/job.dart';
import 'package:work_hub/features/job/logic/job_filter_helper.dart';

void main() {
  group('JobFilterHelper.filterJobsTask', () {
    final now = DateTime.now();

    final job1 = Job(
      id: '1',
      ownerId: 'owner1',
      title: 'Flutter Developer',
      category: 'Mobile',
      description: 'Exp Flutter dev',
      type: 'Full-time',
      workMode: 'Remote',
      requiredSkills: ['Flutter', 'Dart'],
      location: 'Remote',
      status: 'open',
      createdAt: now,
      companyName: 'Tech Corp',
    );

    final job2 = Job(
      id: '2',
      ownerId: 'owner2',
      title: 'Backend Engineer',
      category: 'Backend',
      description: 'Go/Node developer',
      type: 'Full-time',
      workMode: 'Remote',
      requiredSkills: ['Node.js'],
      location: 'Remote',
      status: 'open',
      createdAt: now,
      companyName: 'Backend Solutions',
    );

    final job3 = Job(
      id: '3',
      ownerId: 'owner3',
      title: 'UI Designer',
      category: 'Design',
      description: 'Figma designer',
      type: 'Contract',
      workMode: 'Hybrid',
      requiredSkills: ['Figma'],
      location: 'New York',
      status: 'filled', // Should be filtered out
      createdAt: now,
    );

    final posts = [job1, job2, job3];

    test('should return all open jobs when query is empty', () {
      final params = {
        'posts': posts,
        'query': '',
        'appliedIds': <String>{},
      };

      final result = JobFilterHelper.filterJobsTask(params);

      expect(result.length, 2);
      expect(result.any((j) => j.id == '1'), true);
      expect(result.any((j) => j.id == '2'), true);
      expect(result.any((j) => j.id == '3'), false); // Filled
    });

    test('should filter by title query', () {
      final params = {
        'posts': posts,
        'query': 'Flutter',
        'appliedIds': <String>{},
      };

      final result = JobFilterHelper.filterJobsTask(params);

      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('should filter out applied jobs', () {
      final params = {
        'posts': posts,
        'query': '',
        'appliedIds': {'1'},
      };

      final result = JobFilterHelper.filterJobsTask(params);

      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('should filter by company name', () {
      final params = {
        'posts': posts,
        'query': 'Solutions',
        'appliedIds': <String>{},
      };

      final result = JobFilterHelper.filterJobsTask(params);

      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('should be case insensitive', () {
      final params = {
        'posts': posts,
        'query': 'FLUTTER',
        'appliedIds': <String>{},
      };

      final result = JobFilterHelper.filterJobsTask(params);

      expect(result.length, 1);
      expect(result.first.id, '1');
    });
  });
}
