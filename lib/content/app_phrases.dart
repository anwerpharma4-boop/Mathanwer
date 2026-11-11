// Short spoken phrases used by the app itself (feedback and instructions).
// These are NOT textbook content; they are app UI speech and are bundled as
// British English audio together with the textbook vocabulary.

const List<String> praisePhrases = ['Well done!', 'Great job!', 'Excellent!', 'Super!', 'Fantastic!'];

const List<String> retryPhrases = ['Try again.', 'Have another go.'];

const List<String> instructionPhrases = [
  'Listen and choose the picture.',
  'Match the word to the picture.',
  'Match the big and small letters.',
  'Find the missing letter.',
  'Put the letters in order.',
  'Which colour is it?',
  'How many can you see?',
  'Which animal is it?',
  'Find the classroom object.',
  'Listen and repeat.',
  'Find the pairs.',
  'Drag the picture to its letter.',
  'Trace the letter with your finger.',
  'Find the letter.',
  'Which picture starts with this sound?',
  'Listen and say.',
  'Now you!',
  'You did it!',
];

const List<String> allAppPhrases = [...praisePhrases, ...retryPhrases, ...instructionPhrases];
