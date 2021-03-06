#ifndef MERT_SER_SCORER_H_
#define MERT_SER_SCORER_H_

#include <string>
#include <vector>
#include "Types.h"
#include "StatisticsBasedScorer.h"

namespace MosesTuning
{


class ScoreStats;

/**
 * An implementation of sentence error rate.
 * This is defined as 0 if the sentences are identical and 1 otherwise.
 */
class SerScorer: public StatisticsBasedScorer
{
public:
  explicit SerScorer(const std::string& config = "");
  ~SerScorer();

  virtual void setReferenceFiles(const std::vector<std::string>& referenceFiles);
  virtual void prepareStats(std::size_t sid, const std::string& text, ScoreStats& entry);
  virtual std::size_t NumberOfScores() const {
    return 2;
  }
  virtual float calculateScore(const std::vector<ScoreStatsType>& comps) const;

private:
  // no copying allowed
  SerScorer(const SerScorer&);
  SerScorer& operator=(const SerScorer&);

  typedef std::vector<int> sent_t;
  std::vector<std::vector<sent_t> > m_ref_sentences;
};

}

#endif  // MERT_SER_SCORER_H_
