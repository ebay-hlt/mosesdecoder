#include "PrecScorer.h"

#include <fstream>
#include <stdexcept>
#include <cmath>

#include "ScoreStats.h"
#include "Util.h"

using namespace std;

namespace MosesTuning
{


  PrecScorer::PrecScorer(const string& tname, const string& config)
    : StatisticsBasedScorer(tname,config) {} // tname one of "PREC", "REC", "F1"

  PrecScorer::~PrecScorer() {}

void PrecScorer::extractTokens(const std::string& infile, std::vector<std::vector<int> >& tokens, std::vector<std::size_t>& lengths) {
    tokens.clear();
    lengths.clear();
    ifstream in(infile.c_str());
    if (!in) {
      throw runtime_error("Unable to open " + infile);
    }
    string line;
    int sid = 0;
    while (getline(in,line)) {
      line = this->preprocessSentence(line);
      vector<int> linetoks;
      TokenizeAndEncode(line, linetoks);
      tokens.push_back(vector<int>());
      for (size_t i = 0; i < linetoks.size(); ++i) {
        tokens.back().push_back(linetoks[i]);
      }
      lengths.push_back(linetoks.size());
      if (sid > 0 && sid % 1000 == 0) {
        TRACE_ERR(".");
      }
      ++sid;
    }
    TRACE_ERR("[");
    TRACE_ERR(sid);
    TRACE_ERR("]");
    TRACE_ERR(endl);
}

void PrecScorer::setReferenceFiles(const vector<string>& referenceFiles)
{
  if (referenceFiles.size() != 2) {
    throw runtime_error("Precision/Recall/F1 only supports two input files: source and reference");
  }
  
  extractTokens(referenceFiles[0], m_src_tokens, m_src_lengths);
  extractTokens(referenceFiles[1], m_ref_tokens, m_ref_lengths);

}

void PrecScorer::prepareStats(size_t sid, const string& text, ScoreStats& entry)
{
  if (sid >= m_ref_lengths.size() || sid >= m_src_lengths.size()) {
    stringstream msg;
    string tmp = "source";
    if (sid >= m_ref_lengths.size())
      tmp = "reference";
    msg << "Sentence id (" << sid << ") not found in " << tmp << " set";
    throw runtime_error(msg.str());
  }

  string sentence = this->preprocessSentence(text);

  vector<int> testtokens;
  TokenizeAndEncode(sentence, testtokens);
  int tp = 0; // true positive
  int fp = 0; // false positive
  int tn = 0; // true negative
  int fn = 0; // false negative
  int n = 0; // total negatives
  int p = 0; // total positives
  if (m_src_tokens[sid] == m_ref_tokens[sid]) {
    // src in ref
    n++;
    if (testtokens == m_ref_tokens[sid])
      tn++;
    else
      fp++;
  } else {
    p++;
    // src not in ref
    if (testtokens == m_ref_tokens[sid])
      tp++;
    else if (testtokens == m_src_tokens[sid])
      fn++;
    else {
      fp++;
      fn++;
      n++;
    }
  }

  ostringstream stats;
  stats << tp << " " << fp << " " << tn << " " << fn << " " << p << " " << n;
  string stats_str = stats.str();
  entry.set(stats_str);
}

float PrecScorer::calculateScore(const vector<int>& comps) const
{
  float tp = comps[0];
  float fp = comps[1];
  float tn = comps[2];
  float fn = comps[3];
  float p = comps[4];
  float n = comps[5];
  string tname = this->getName();
  float nom = 0.0;
  float denom = 0.0;
  if (tname == "PREC") {
      nom = tp;
      denom = tp+fp;
  } else if (tname == "REC") {
      nom = tp;
      denom = p;
  } else if (tname == "F1") {
      nom = 2*tp;
      denom = 2*tp+fp+fn;
  } else if (tname == "F0.5") {
      float beta = 0.5;
      float beta2 = beta*beta;
      nom = (1+beta2)*tp;
      denom = (1+beta2)*tp+beta2*fn+fp;
  } else if (tname == "LIN1") {
      nom = tp+tn-fp-fn;
      denom = 1;
  } else if (tname == "MCC") {
      nom = (tp*tn) - (fp*fn);
      denom = std::sqrt((tp+fp) * (tp+fn) * (tn+fp) * (tn+fn));
  }
  //this is insane debugging
  /*
  TRACE_ERR(tname+"=");
  TRACE_ERR(nom);
  TRACE_ERR("/");
  TRACE_ERR(denom);
  TRACE_ERR(endl);
  */
  if (denom == 0.0) {
    // This shouldn't happen!
    return 0.0;
  } else if (tname == "MCC") {
    // scale from -1..1 to 0..1 for optimization purposes
    return (nom/denom)*0.5 + 0.5;
  } else {
    return nom/denom;
  }
}

}

