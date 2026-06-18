/// Visual moods for the AI Buddy (Pip).
///
/// Kept separate from [AudioState] on purpose: the buddy's mood is a *view*
/// concern derived from app state, not the audio engine's truth. Decoupling
/// them means we can make Pip "happy" on a correct answer even though no audio
/// is playing.
enum BuddyState {
  idle,
  listening,
  narrating,
  success,
}
