#ifndef MERT_PREC_SCORER_H_
#define MERT_PREC_SCORER_H_

#include <set>
#include <string>
#include <vector>
#include "Types.h"
#include "StatisticsBasedScorer.h"

namespace MosesTuning
{


class ScoreStats;

/**
 * An implementation of Precision, takes 2 "references": original source and reference file.
 */
class PrecScorer: public StatisticsBasedScorer
{
public:
  explicit PrecScorer(const std::string& tname, const std::string& config = "");
  ~PrecScorer();

  virtual void setReferenceFiles(const std::vector<std::string>& referenceFiles); // must be 2 files exactly: src+trg
  virtual void prepareStats(std::size_t sid, const std::string& text, ScoreStats& entry);
  virtual std::size_t NumberOfScores() const {
    return 3;
  }
  virtual float calculateScore(const std::vector<int>& comps) const;

private:
  // no copying allowed
  PrecScorer(const PrecScorer&);
  PrecScorer& operator=(const PrecScorer&);

  void extractTokens(const std::string& infile,
                     std::vector<std::vector<int> >& tokens,
                     std::vector<std::size_t>& lengths);

  // data extracted from reference files
  std::vector<std::size_t> m_ref_lengths;
  std::vector<std::vector<int> > m_ref_tokens;

  // data extracted from reference files
  std::vector<std::size_t> m_src_lengths;
  std::vector<std::vector<int> > m_src_tokens;

};

}

#endif  // MERT_PREC_SCORER_H_
