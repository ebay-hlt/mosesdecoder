/*
 * TrellisPath.cpp
 *
 *  Created on: 2 Aug 2016
 *      Author: hieu
 */
#include <boost/foreach.hpp>
#include <sstream>
#include "TrellisPath.h"
#include "Hypothesis.h"
#include "Manager.h"
#include "TargetPhraseImpl.h"
#include "../TrellisPaths.h"
#include "util/exception.hh"

using namespace std;

namespace Moses2
{

namespace SCFG
{
TrellisNode::TrellisNode(const SCFG::Manager &mgr, const ArcLists &arcLists, const SCFG::Hypothesis &hypo)
:arcList(arcLists.GetArcList(&hypo))
,ind(0)
//,m_prevNodes(pool)
{
  UTIL_THROW_IF2(arcList.size() == 0, "Empty arclist");

  // usually the same as hypo, except when scores are equal
  const SCFG::Hypothesis &thisHypo = GetHypothesis();

  CreateTail(mgr, arcLists, thisHypo);
}

TrellisNode::TrellisNode(const SCFG::Manager &mgr, const ArcLists &arcLists, const ArcList &varcList, size_t vind)
:arcList(varcList)
,ind(vind)
//,m_prevNodes(pool)
{
  UTIL_THROW_IF2(vind >= arcList.size(), "arclist out of bound" << ind << " >= " << arcList.size());
  const SCFG::Hypothesis &hypo = arcList[ind]->Cast<SCFG::Hypothesis>();
  CreateTail(mgr, arcLists, hypo);
}

TrellisNode::TrellisNode(const SCFG::Manager &mgr, const ArcLists &arcLists, const TrellisNode &orig, const TrellisNode &nodeToChange)
:arcList(orig.arcList)
,ind(orig.ind)
//,m_prevNodes(pool)
{
  const TrellisNode::Children &origChildren = orig.GetChildren();
  m_prevNodes.resize(origChildren.size(), NULL);

  for (size_t i = 0; i < origChildren.size(); ++i) {
    TrellisNode *newChild;
    const TrellisNode *origChild = origChildren[i];
    if (origChild != &nodeToChange) {
      // recurse. The child node is not the 1 we need to change
      newChild = new TrellisNode(mgr, arcLists, *origChild, nodeToChange);
    }
    else {
      // need to change the child node
      size_t nextInd = nodeToChange.ind + 1;
      newChild = new TrellisNode(mgr, arcLists, nodeToChange.arcList, nextInd);
    }

    m_prevNodes[i] = newChild;
  }
}

TrellisNode::~TrellisNode()
{
	BOOST_FOREACH(const TrellisNode *child, m_prevNodes) {
		delete child;
	}
}


void TrellisNode::CreateTail(const SCFG::Manager &mgr, const ArcLists &arcLists, const SCFG::Hypothesis &hypo)
{
  const Vector<const Hypothesis*> &prevHypos = hypo.GetPrevHypos();
  m_prevNodes.resize(prevHypos.size(), NULL);

  for (size_t i = 0; i < hypo.GetPrevHypos().size(); ++i) {
	const SCFG::Hypothesis &prevHypo = *prevHypos[i];
	TrellisNode *prevNode = new TrellisNode(mgr, arcLists, prevHypo);
	m_prevNodes[i] = prevNode;
  }
}

const SCFG::Hypothesis &TrellisNode::GetHypothesis() const
{
  UTIL_THROW_IF2(ind >= arcList.size(), "Arcs requested out of bound. " << arcList.size() << "<" << ind);
  const SCFG::Hypothesis &hypo = arcList[ind]->Cast<SCFG::Hypothesis>();
  return hypo;
}

void TrellisNode::OutputToStream(const System &system, std::stringstream &strm) const
{
  const SCFG::Hypothesis &hypo = GetHypothesis();
  const SCFG::TargetPhraseImpl &tp = hypo.GetTargetPhrase();
  //cerr << "tp=" << tp.Debug(m_mgr->system) << endl;

  for (size_t pos = 0; pos < tp.GetSize(); ++pos) {
	const SCFG::Word &word = tp[pos];
	//cerr << "word " << pos << "=" << word << endl;
	if (word.isNonTerminal) {
	  //cerr << "is nt" << endl;
	  // non-term. fill out with prev hypo
	  size_t nonTermInd = tp.GetAlignNonTerm().GetNonTermIndexMap()[pos];

	  if (nonTermInd >= m_prevNodes.size()) {
		  cerr << endl << "tp=" << tp.Debug(system) << endl;
		  cerr << "ant alignment=" << tp.GetAlignNonTerm().Debug(system) << endl;
		  cerr << "pos=" << pos << endl;
	  }
	  UTIL_THROW_IF2(nonTermInd >= m_prevNodes.size(), "Out of bounds:" << nonTermInd << ">=" << m_prevNodes.size());

	  const TrellisNode *prevNode = m_prevNodes[nonTermInd];
	  UTIL_THROW_IF2(prevNode == NULL, "prevNode == NULL");

	  prevNode->OutputToStream(system, strm);
	}
	else {
	  //cerr << "not nt" << endl;
	  word.OutputToStream(strm);
	  strm << " ";
	}
  }
}

bool TrellisNode::HasMore() const
{
	bool ret = arcList.size() > (ind + 1);
	return ret;
}

/////////////////////////////////////////////////////////////////////

TrellisPath::TrellisPath(const SCFG::Manager &mgr, const SCFG::Hypothesis &hypo)
{
  //cerr << "create2 " << this << endl;
  MemPool &pool = mgr.GetPool();

  // 1st
  m_scores =   m_scores = new (pool.Allocate<Scores>())
		  Scores(mgr.system,  pool, mgr.system.featureFunctions.GetNumScores(), hypo.GetScores());
  m_node = new TrellisNode(mgr, mgr.arcLists, hypo);
  m_prevNodeChanged = m_node;

  ComputeStr(mgr.system);
}

TrellisPath::TrellisPath(const SCFG::Manager &mgr, const SCFG::TrellisPath &origPath, const TrellisNode &nodeToChange)
:m_node(NULL)
,m_scores(NULL)
,m_prevNodeChanged(NULL)
{
  //cerr << "create1 " << this << endl;

  MemPool &pool = mgr.GetPool();

  // calc scores
  m_scores = new (pool.Allocate<Scores>())
			  Scores(mgr.system,  pool, mgr.system.featureFunctions.GetNumScores(), origPath.GetScores());
  m_scores->MinusEquals(mgr.system, nodeToChange.GetHypothesis().GetScores());

  const SCFG::Hypothesis &nextHypo = nodeToChange.arcList[nodeToChange.ind + 1]->Cast<SCFG::Hypothesis>();
  m_scores->PlusEquals(mgr.system, nextHypo.GetScores());

  if (origPath.m_node == &nodeToChange) {
	  m_node = new TrellisNode(mgr, mgr.arcLists, nodeToChange.arcList, nodeToChange.ind + 1);
	  m_prevNodeChanged= m_node;
  }
  else {
	  // recursively copy nodes until we find the node that needs to change
	  m_node = new TrellisNode(mgr, mgr.arcLists, *origPath.m_node, nodeToChange);
	  m_prevNodeChanged= m_node;
  }

  ComputeStr(mgr.system);
}

TrellisPath::~TrellisPath()
{
	//cerr << "delete " << this << endl;
	delete m_node;
}

void TrellisPath::ComputeStr(const System &system)
{
  stringstream tmpStrm;
  UTIL_THROW_IF2(m_node == NULL, "m_node == NULL");
  m_node->OutputToStream(system, tmpStrm);

  m_out = tmpStrm.str();
  m_out = m_out.substr(4, m_out.size() - 10);
}

SCORE TrellisPath::GetFutureScore() const
{
  return m_scores->GetTotalScore();
}

//! create a set of next best paths by wiggling 1 of the node at a time.
void TrellisPath::CreateDeviantPaths(TrellisPaths<SCFG::TrellisPath> &paths, const SCFG::Manager &mgr) const
{
	if (m_prevNodeChanged->HasMore()) {
		MemPool &pool = mgr.GetPool();

		//cerr << "BEGIN deviantPath" << endl;
		SCFG::TrellisPath *deviantPath = new SCFG::TrellisPath(mgr, *this, *m_prevNodeChanged);
		//cerr << "END deviantPath" << endl;
		paths.Add(deviantPath);
		//cerr << "ADDED deviantPath" << endl;
	}

	// recursively wiggle all of it's child nodes
	CreateDeviantPaths(paths, mgr, *m_prevNodeChanged);
}

void TrellisPath::CreateDeviantPaths(
    TrellisPaths<SCFG::TrellisPath> &paths,
    const SCFG::Manager &mgr,
    const TrellisNode &parentNode) const
{
  const TrellisNode::Children &children = parentNode.GetChildren();
  BOOST_FOREACH(const TrellisNode *child, children) {
    if (child->HasMore()) {
      SCFG::TrellisPath *deviantPath = new TrellisPath(mgr, *this, *child);
      paths.Add(deviantPath);
    }

    // recurse
    CreateDeviantPaths(paths, mgr, *child);

  }
}

std::string TrellisPath::Debug(const System &system) const
{
  stringstream out;
  out << "path=" << this << " "
      << "node=" << m_node << " "
      << "arclist=" << &m_node->arcList << " "
      << "ind=" << m_node->ind << endl;
  return out.str();
}

} // namespace
}


