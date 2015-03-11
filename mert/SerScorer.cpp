#include "SerScorer.h"

#include <fstream>
#include <stdexcept>

#include "ScoreStats.h"
#include "Util.h"

using namespace std;

namespace MosesTuning
{


SerScorer::SerScorer(const string& config)
  : StatisticsBasedScorer("SER",config) {}

SerScorer::~SerScorer() {}

void SerScorer::setReferenceFiles(const vector<string>& referenceFiles)
{
  // For each line in the reference file, create a multiset of
  // the word ids.
  if (referenceFiles.size() != 1) {
    throw runtime_error("SER only supports a single reference");
  }
  m_ref_tokens.clear();
  m_ref_lengths.clear();
  ifstream in(referenceFiles[0].c_str());
  if (!in) {
    throw runtime_error("Unable to open " + referenceFiles[0]);
  }
  string line;
  int sid = 0;
  while (getline(in,line)) {
    line = this->preprocessSentence(line);
    vector<int> tokens;
    TokenizeAndEncode(line, tokens);
    m_ref_tokens.push_back(vector<int>());
    for (size_t i = 0; i < tokens.size(); ++i) {
      m_ref_tokens.back().push_back(tokens[i]);
    }
    m_ref_lengths.push_back(tokens.size());
    if (sid > 0 && sid % 100 == 0) {
      TRACE_ERR(".");
    }
    ++sid;
  }
  TRACE_ERR(endl);

}

void SerScorer::prepareStats(size_t sid, const string& text, ScoreStats& entry)
{
  if (sid >= m_ref_lengths.size()) {
    stringstream msg;
    msg << "Sentence id (" << sid << ") not found in reference set";
    throw runtime_error(msg.str());
  }

  string sentence = this->preprocessSentence(text);

  // Calculate correct, output_length and ref_length for
  // the line and store it in entry
  vector<int> testtokens;
  TokenizeAndEncode(sentence, testtokens);
  int correct = 0;
  if (testtokens.size() == m_ref_tokens[sid].size() && testtokens == m_ref_tokens[sid]) {
    correct++;
  }

  ostringstream stats;
  stats << correct << " 1 1 ";
  string stats_str = stats.str();
  entry.set(stats_str);
}

float SerScorer::calculateScore(const vector<int>& comps) const
{
  float denom = comps[2];
  float num = comps[0];
  if (denom == 0) {
    // This shouldn't happen!
    return 0.0;
  } else {
    return num/denom;
  }
}

}

