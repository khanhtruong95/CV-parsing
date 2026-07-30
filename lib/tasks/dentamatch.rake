namespace :dentamatch do
  desc "Purge stale in-progress candidate profiles (and their CV blobs) older than 30 days"
  task purge_stale: :environment do
    count = CandidateProfile.purge_stale!
    puts "Purged #{count} stale draft profile(s)."
  end
end
