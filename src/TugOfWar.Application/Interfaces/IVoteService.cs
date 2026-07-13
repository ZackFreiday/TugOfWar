using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Interfaces;

public interface IVoteService
{
    Task<Vote> SubmitVote(int userId, int faceOffId, SubmitVoteRequest request);
}
