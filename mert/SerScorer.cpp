#include "SerScorer.h"

#include <fstream>
#include <stdexcept>

//#include "ScoreStats.h"
//#include "Util.h"

using namespace std;

namespace MosesTuning
{


SerScorer::SerScorer(const string& config)
  : StatisticsBasedScorer("SER",config) {}

SerScorer::~SerScorer() {}

void SerScorer::setReferenceFiles(const vector<string>& referenceFiles)
{
  //make sure reference data is clear
  m_ref_sentences.clear();

  //load reference data
  for (size_t rid = 0; rid < referenceFiles.size(); ++rid) {
    ifstream refin(referenceFiles[rid].c_str());
    if (!refin) {
      throw runtime_error("Unable to open: " + referenceFiles[rid]);
    }
    m_ref_sentences.push_back(vector<sent_t>());
    string line;
    while (getline(refin,line)) {
      line = this->preprocessSentence(line);
      sent_t encoded;
      TokenizeAndEncode(line, encoded);
      m_ref_sentences[rid].push_back(encoded);
    }
  }
}

void SerScorer::prepareStats(size_t sid, const string& text, ScoreStats& entry)
{
  if (sid >= m_ref_sentences[0].size()) {
    stringstream msg;
    msg << "Sentence id (" << sid << ") not found in reference set";
    throw runtime_error(msg.str());
  }

  string sentence = this->preprocessSentence(text);
  int n_ser = 1; // if we don't find a reference of the same length, the error is 1

  // Check whether the guessed text is equal to the reference 
  // for this line and store it in entry
  vector<int> testtokens;
  TokenizeAndEncode(sentence, testtokens);
  for (size_t rid = 0; rid < m_ref_sentences.size(); ++rid) {
    const sent_t& ref = m_ref_sentences[rid][sid];

    // we can only have a perfect match if the sentence length is equal
    if (testtokens.size() == ref.size()) {
      int errors = 0;
      for (size_t tid = 0; tid < testtokens.size(); tid++) {
	// token mismatch: error 1 w.r.t. this reference; move to next ref.
	if (ref[tid] != testtokens[tid]) { 
	  errors = 1;
	  break;
	}
      }
      if (errors == 0) {
        n_ser = 0;
        break;
      }
    }
  }
  ostringstream stats;
  stats << n_ser << " " << 1; // sentence error (0 or 1), number of sentences (1)
  string stats_str = stats.str();
  entry.set(stats_str);
}

float SerScorer::calculateScore(const vector<ScoreStatsType>& comps) const
{
  return 1.0f - (comps[0] / static_cast<float>(comps[1]));
}

}

